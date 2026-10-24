package com.sentinel.ui

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import com.sentinel.core.logs.LogManager
import com.sentinel.core.logs.LogRetention
import com.sentinel.core.rules.FirewallOptionsStore
import com.sentinel.core.rules.RuleEngine
import com.sentinel.core.vpn.SentinelVpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val engineId = "main_engine"
    private val REQ_VPN = 0x5601
    private var startResultSink: EventChannel.EventSink? = null
    private lateinit var ruleEngine: RuleEngine

    override fun onCreate(savedInstanceState: Bundle?) {
        if (FlutterEngineCache.getInstance().get(engineId) == null) {
            val engine = FlutterEngine(applicationContext)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            FlutterEngineCache.getInstance().put(engineId, engine)
        }
        super.onCreate(savedInstanceState)
        ruleEngine = RuleEngine.getInstance(applicationContext)
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(engineId)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val scope = CoroutineScope(Dispatchers.IO)

        MethodChannel(messenger, "com.aitechdb.security.security_monitor/bridge")
            .setMethodCallHandler { call, result ->
                scope.launch {
                    try {
                        when (call.method) {
                            "startVpn" -> {
                                val intent = VpnService.prepare(this@MainActivity)
                                if (intent != null) {
                                    startActivityForResult(intent, REQ_VPN)
                                    result.success(true)
                                } else {
                                    startService(Intent(this@MainActivity, SentinelVpnService::class.java))
                                    startResultSink?.success(true)
                                    result.success(true)
                                }
                            }
                            "stopVpn" -> {
                                val serviceIntent = Intent(this@MainActivity, SentinelVpnService::class.java)
                                serviceIntent.action = SentinelVpnService.ACTION_STOP
                                startService(serviceIntent)
                                result.success(null)
                            }
                            "getStatus" -> result.success(SentinelVpnService.isRunning.value)
                            "getInstalledApps" -> result.success(getInstalledApps())
                            "getBlacklist" -> {
                                result.success(ruleEngine.getUserBlockedDomains())
                            }
                            "getLogRetention" -> {
                                val hours = FirewallOptionsStore.read(this@MainActivity).logRetentionHours
                                val label = when (hours) {
                                    LogRetention.OFF -> "OFF"
                                    LogRetention.HOURS_24 -> "24H"
                                    LogRetention.DAYS_3 -> "3D"
                                    else -> "${hours}H"
                                }
                                result.success(label)
                            }
                            "exitApp" -> {
                                val serviceIntent = Intent(this@MainActivity, SentinelVpnService::class.java)
                                serviceIntent.action = SentinelVpnService.ACTION_STOP
                                startService(serviceIntent)
                                result.success(true)
                                // Distruggi l'engine Flutter per forzare un riavvio pulito
                                FlutterEngineCache.getInstance().get(engineId)?.destroy()
                                FlutterEngineCache.getInstance().remove(engineId)
                                finishAffinity()
                            }
                            "setLogRetention" -> {
                                val label = call.argument<String>("value")
                                val hours = when (label) {
                                    "OFF" -> LogRetention.OFF
                                    "24H" -> LogRetention.HOURS_24
                                    "3D" -> LogRetention.DAYS_3
                                    else -> LogRetention.DEFAULT_HOURS
                                }
                                FirewallOptionsStore.update(this@MainActivity) {
                                    it.copy(logRetentionHours = hours)
                                }
                                LogManager.setRetentionHours(hours)
                                LogManager.trimNow()
                                result.success(true)
                            }
                            "addToBlacklist" -> {
                                val domain = call.argument<String>("domain")
                                if (domain == null) {
                                    result.error("ARG", "domain mancante", null)
                                } else {
                                    ruleEngine.addBlockRule(domain, -1, "", "USER")
                                    result.success(ruleEngine.getUserBlockedDomains())
                                }
                            }
                            "removeFromBlacklist" -> {
                                val domain = call.argument<String>("domain")
                                if (domain == null) {
                                    result.error("ARG", "domain mancante", null)
                                } else {
                                    ruleEngine.removeBlockRule(domain)
                                    result.success(ruleEngine.getUserBlockedDomains())
                                }
                            }
                            "getApkSignature" -> {
                                val pkg = call.argument<String>("packageName")
                                if (pkg == null) result.error("ARG", "packageName mancante", null)
                                else result.success(getApkSignature(pkg))
                            }
                            "requestIgnoreBatteryOptimization" -> {
                                try {
                                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                    intent.data = Uri.parse("package:$packageName")
                                    startActivity(intent)
                                    result.success(true)
                                } catch (e: Exception) { result.error("BATTERY", e.message, null) }
                            }
                            else -> result.notImplemented()
                        }
                    } catch (e: Exception) {
                        result.error("NATIVE_ERROR", e.message, null)
                    }
                }
            }

        EventChannel(messenger, "com.aitechdb.security.security_monitor/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var job: Job? = null
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events == null) return
                    job = CoroutineScope(Dispatchers.Main).launch {
                        LogManager.recentLogs.collect { logs ->
                            logs.forEach { log ->
                                val allowed = log.status != "BLOCKED"
                                events.success(mapOf(
                                    "uid" to uidOf(log.packageName),
                                    "packageName" to log.packageName,
                                    "host" to log.destination,
                                    "port" to 0,
                                    "protocol" to "dns",
                                    "timestamp" to log.timestampMs,
                                    "allowed" to allowed,
                                    "threatLabel" to log.threatLabel
                                ))
                            }
                        }
                    }
                }
                override fun onCancel(arguments: Any?) { job?.cancel(); job = null }
            })

        EventChannel(messenger, "com.aitechdb.security.security_monitor/start_result")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    startResultSink = events
                }
                override fun onCancel(arguments: Any?) {
                    startResultSink = null
                }
            })
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_VPN) {
            val granted = resultCode == Activity.RESULT_OK
            if (granted) {
                startService(Intent(this, SentinelVpnService::class.java))
            }
            startResultSink?.success(granted)
        }
    }

    private fun uidOf(pkg: String?): Int {
        if (pkg.isNullOrBlank()) return -1
        return try {
            packageManager.getApplicationInfo(pkg, 0).uid
        } catch (e: Exception) { -1 }
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val flags = PackageManager.GET_PERMISSIONS or PackageManager.GET_SIGNING_CERTIFICATES
        return pm.getInstalledPackages(flags).map { p ->
            mapOf(
                "packageName" to p.packageName,
                "label" to runCatching { pm.getApplicationLabel(p.applicationInfo!!).toString() }.getOrDefault(p.packageName),
                "versionName" to (p.versionName ?: ""),
                "firstInstallTime" to p.firstInstallTime,
                "lastUpdateTime" to p.lastUpdateTime,
                "isSystem" to ((p.applicationInfo?.flags ?: 0) and android.content.pm.ApplicationInfo.FLAG_SYSTEM != 0),
                "isDeviceAdmin" to false,
                "permissions" to (p.requestedPermissions?.toList() ?: emptyList<String>())
            )
        }
    }

    private fun getApkSignature(pkg: String): Map<String, Any?>? {
        return try {
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                packageManager.getPackageInfo(pkg, PackageManager.GET_SIGNING_CERTIFICATES)
            else @Suppress("DEPRECATION") packageManager.getPackageInfo(pkg, PackageManager.GET_SIGNATURES)
            val certs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                info.signingInfo?.apkContentsSigners
            else @Suppress("DEPRECATION") info.signatures
            if (certs == null || certs.isEmpty()) return null
            val sha256 = certs.map { sig ->
                MessageDigest.getInstance("SHA-256").digest(sig.toByteArray()).joinToString(":") { "%02X".format(it) }
            }
            mapOf("packageName" to pkg, "sha256" to sha256)
        } catch (e: Exception) { null }
    }
}

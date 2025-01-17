package com.example.vpn_app

import io.flutter.embedding.android.FlutterActivity
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.VpnService
import android.app.Activity

class MainActivity: FlutterActivity() {
    private val CHANNEL = "vpn_channel"
    private val VPN_REQUEST_CODE = 24

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkVPNPermission" -> {
                    val vpnIntent = VpnService.prepare(context)
                    if (vpnIntent != null) {
                        startActivityForResult(vpnIntent, VPN_REQUEST_CODE)
                        result.success(false)
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            OpenVPNFlutterPlugin.connectWhileGranted(true)
        } else {
            OpenVPNFlutterPlugin.connectWhileGranted(false)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
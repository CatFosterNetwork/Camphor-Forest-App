package social.swu.camphor_forest

import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 启用edge-to-edge显示
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // 设置状态栏颜色为透明
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.statusBarColor = android.graphics.Color.TRANSPARENT
        }
        
        // 根据当前主题设置正确的状态栏图标颜色
        updateStatusBarIcons()
    }
    
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // 主题改变时更新状态栏
        updateStatusBarIcons()
    }
    
    private fun updateStatusBarIcons() {
        val currentNightMode = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        val isDarkMode = currentNightMode == Configuration.UI_MODE_NIGHT_YES
        
        // 使用现代的WindowInsetsController API
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightStatusBars = !isDarkMode
    }
}

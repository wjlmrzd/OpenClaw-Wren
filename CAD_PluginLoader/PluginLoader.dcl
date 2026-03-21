/* ============================================================================
   PluginLoader.dcl - AutoCAD/中望 CAD 插件加载器对话框定义
   ============================================================================
   版本：1.0.0
   兼容平台：
     - AutoCAD 2014-2026
     - 中望 CAD 2024-2026
   
   对话框布局说明：
     - 顶部：标题和插件列表
     - 中部：列表显示所有配置的插件
     - 底部：操作按钮组
   ============================================================================ */

PluginLoader : dialog
{
    /* 对话框基本属性 */
    label = "插件加载器管理器 - PluginLoader v1.0";
    key = "PluginLoader";
    width = 80;
    height = 30;
    alignment = centered;
    spacing = 1;
    margin = 2;
    
    /* 垂直布局 - 主容器 */
    : column
    {
        alignment = left;
        spacing = 1;
        
        /* 顶部信息区域 */
        : row
        {
            alignment = left;
            spacing = 2;
            
            /* 图标占位 */
            : image
            {
                key = "header_image";
                width = 5;
                height = 3;
                color = 255;
            }
            
            /* 说明文字 */
            : column
            {
                alignment = left;
                spacing = 0.5;
                
                : text
                {
                    label = "插件加载器管理器";
                    alignment = left;
                    width = 40;
                }
                
                : text
                {
                    label = "管理您的 CAD 插件加载路径和配置";
                    alignment = left;
                    width = 40;
                    color = 255;
                }
            }
        }
        
        /* 分隔线 */
        : separator
        {
            width = 75;
        }
        
        /* 插件列表区域 */
        : column
        {
            alignment = left;
            spacing = 0.5;
            
            /* 列表标题 */
            : row
            {
                alignment = left;
                spacing = 1;
                
                : text
                {
                    label = "插件名称";
                    width = 20;
                    alignment = left;
                    color = 255;
                }
                
                : text
                {
                    label = "版本";
                    width = 10;
                    alignment = left;
                    color = 255;
                }
                
                : text
                {
                    label = "状态";
                    width = 8;
                    alignment = left;
                    color = 255;
                }
                
                : text
                {
                    label = "描述";
                    width = 35;
                    alignment = left;
                    color = 255;
                }
            }
            
            /* 插件列表控件 */
            : list_box
            {
                key = "plugin_list";
                width = 75;
                height = 12;
                tabs = "20 30 38 75";
                multiple_select = false;
                value = "";
            }
        }
        
        /* 分隔线 */
        : separator
        {
            width = 75;
        }
        
        /* 操作按钮区域 */
        : row
        {
            alignment = centered;
            spacing = 2;
            
            /* 添加按钮 */
            : button
            {
                key = "add_btn";
                label = "添加 (&A)";
                width = 12;
                is_default = false;
                mnemonic = "A";
            }
            
            /* 编辑按钮 */
            : button
            {
                key = "edit_btn";
                label = "编辑 (&E)";
                width = 12;
                is_default = false;
                mnemonic = "E";
            }
            
            /* 删除按钮 */
            : button
            {
                key = "delete_btn";
                label = "删除 (&D)";
                width = 12;
                is_default = false;
                mnemonic = "D";
            }
            
            /* 切换状态按钮 */
            : button
            {
                key = "toggle_btn";
                label = "启用/禁用 (&T)";
                width = 14;
                is_default = false;
                mnemonic = "T";
            }
            
            /* 重新加载按钮 */
            : button
            {
                key = "reload_btn";
                label = "重新加载 (&R)";
                width = 14;
                is_default = false;
                mnemonic = "R";
            }
        }
        
        /* 底部状态信息 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : text
            {
                label = "提示：双击插件可切换启用状态";
                alignment = left;
                width = 40;
                color = 255;
            }
        }
        
        /* 分隔线 */
        : separator
        {
            width = 75;
        }
        
        /* 底部标准按钮 */
        : row
        {
            alignment = right;
            spacing = 2;
            
            /* 确定按钮 */
            : button
            {
                key = "accept";
                label = "确定";
                width = 12;
                is_default = true;
                is_cancel = false;
            }
            
            /* 取消按钮 */
            : button
            {
                key = "cancel";
                label = "取消";
                width = 12;
                is_default = false;
                is_cancel = true;
            }
            
            /* 帮助按钮 */
            : button
            {
                key = "help_btn";
                label = "帮助 (&H)";
                width = 12;
                is_default = false;
                mnemonic = "H";
                action = "(PL:ShowHelp)";
            }
        }
    }
}

/* ============================================================================
   辅助对话框 - 添加插件
   ============================================================================ */
PluginLoader_Add : dialog
{
    label = "添加插件";
    key = "PluginLoader_Add";
    width = 60;
    height = 20;
    alignment = centered;
    spacing = 1;
    margin = 2;
    
    : column
    {
        alignment = left;
        spacing = 1;
        
        /* 插件路径 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : text
            {
                label = "插件路径 (&P):";
                width = 15;
                alignment = left;
            }
            
            : edit_box
            {
                key = "path_edit";
                width = 40;
                edit_width = 40;
            }
            
            : button
            {
                key = "browse_btn";
                label = "浏览...";
                width = 10;
                action = "(PL:BrowseFile)";
            }
        }
        
        /* 插件名称 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : text
            {
                label = "插件名称 (&N):";
                width = 15;
                alignment = left;
            }
            
            : edit_box
            {
                key = "name_edit";
                width = 40;
                edit_width = 40;
            }
        }
        
        /* 版本号 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : text
            {
                label = "版本号 (&V):";
                width = 15;
                alignment = left;
            }
            
            : edit_box
            {
                key = "version_edit";
                width = 20;
                edit_width = 20;
                value = "1.0";
            }
        }
        
        /* 描述 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : text
            {
                label = "描述 (&D):";
                width = 15;
                alignment = left;
            }
            
            : edit_box
            {
                key = "desc_edit";
                width = 40;
                edit_width = 40;
            }
        }
        
        /* 分隔线 */
        : separator
        {
            width = 55;
        }
        
        /* 底部按钮 */
        : row
        {
            alignment = right;
            spacing = 2;
            
            : button
            {
                key = "accept";
                label = "确定";
                width = 12;
                is_default = true;
            }
            
            : button
            {
                key = "cancel";
                label = "取消";
                width = 12;
                is_default = false;
                is_cancel = true;
            }
        }
    }
}

/* ============================================================================
   辅助对话框 - 编辑插件
   ============================================================================ */
PluginLoader_Edit : dialog
{
    label = "编辑插件";
    key = "PluginLoader_Edit";
    width = 60;
    height = 20;
    alignment = centered;
    spacing = 1;
    margin = 2;
    
    : column
    {
        alignment = left;
        spacing = 1;
        
        /* 插件路径 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : text
            {
                label = "插件路径 (&P):";
                width = 15;
                alignment = left;
            }
            
            : edit_box
            {
                key = "path_edit";
                width = 40;
                edit_width = 40;
            }
            
            : button
            {
                key = "browse_btn";
                label = "浏览...";
                width = 10;
                action = "(PL:BrowseFile \"path_edit\")";
            }
        }
        
        /* 插件名称 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : text
            {
                label = "插件名称 (&N):";
                width = 15;
                alignment = left;
            }
            
            : edit_box
            {
                key = "name_edit";
                width = 40;
                edit_width = 40;
            }
        }
        
        /* 版本号 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : text
            {
                label = "版本号 (&V):";
                width = 15;
                alignment = left;
            }
            
            : edit_box
            {
                key = "version_edit";
                width = 20;
                edit_width = 20;
            }
        }
        
        /* 描述 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : text
            {
                label = "描述 (&D):";
                width = 15;
                alignment = left;
            }
            
            : edit_box
            {
                key = "desc_edit";
                width = 40;
                edit_width = 40;
            }
        }
        
        /* 启用状态 */
        : row
        {
            alignment = left;
            spacing = 1;
            
            : toggle_button
            {
                key = "enabled_toggle";
                label = "启用此插件 (&E)";
                width = 20;
                value = "1";
            }
        }
        
        /* 分隔线 */
        : separator
        {
            width = 55;
        }
        
        /* 底部按钮 */
        : row
        {
            alignment = right;
            spacing = 2;
            
            : button
            {
                key = "accept";
                label = "确定";
                width = 12;
                is_default = true;
            }
            
            : button
            {
                key = "cancel";
                label = "取消";
                width = 12;
                is_default = false;
                is_cancel = true;
            }
        }
    }
}

/* ============================================================================
   辅助对话框 - 帮助信息
   ============================================================================ */
PluginLoader_Help : dialog
{
    label = "PluginLoader 帮助";
    key = "PluginLoader_Help";
    width = 60;
    height = 25;
    alignment = centered;
    spacing = 1;
    margin = 2;
    
    : column
    {
        alignment = left;
        spacing = 1;
        
        : text
        {
            label = "PluginLoader 插件加载器";
            alignment = centered;
            width = 55;
            color = 255;
        }
        
        : text
        {
            label = "版本 1.0.0";
            alignment = centered;
            width = 55;
        }
        
        : separator
        {
            width = 55;
        }
        
        : text
        {
            label = "功能说明：";
            alignment = left;
            width = 55;
            color = 255;
        }
        
        : text
        {
            label = "  • 集中管理所有 CAD 插件加载路径";
            alignment = left;
            width = 55;
        }
        
        : text
        {
            label = "  • 自动加载配置的插件";
            alignment = left;
            width = 55;
        }
        
        : text
        {
            label = "  • 支持插件的启用/禁用";
            alignment = left;
            width = 55;
        }
        
        : text
        {
            label = "  • 显示插件详细信息";
            alignment = left;
            width = 55;
        }
        
        : separator
        {
            width = 55;
        }
        
        : text
        {
            label = "使用方法：";
            alignment = left;
            width = 55;
            color = 255;
        }
        
        : text
        {
            label = "  1. 输入 PLM 命令打开管理界面";
            alignment = left;
            width = 55;
        }
        
        : text
        {
            label = "  2. 点击\"添加\"按钮选择插件文件";
            alignment = left;
            width = 55;
        }
        
        : text
        {
            label = "  3. 使用\"启用/禁用\"控制插件加载";
            alignment = left;
            width = 55;
        }
        
        : text
        {
            label = "  4. 点击\"确定\"保存并重新加载";
            alignment = left;
            width = 55;
        }
        
        : separator
        {
            width = 55;
        }
        
        : text
        {
            label = "兼容平台：AutoCAD 2014-2026, 中望 CAD 2024-2026";
            alignment = left;
            width = 55;
        }
        
        : spacer
        {
            height = 1;
        }
        
        : row
        {
            alignment = right;
            spacing = 2;
            
            : button
            {
                key = "accept";
                label = "关闭";
                width = 12;
                is_default = true;
                is_cancel = true;
            }
        }
    }
}

/* ============================================================================
   结束
   ============================================================================ */

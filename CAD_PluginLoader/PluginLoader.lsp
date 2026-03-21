;;; ============================================================================
;;; PluginLoader.lsp - AutoCAD/中望 CAD 插件加载器
;;; ============================================================================
;;; 版本：1.0.0
;;; 作者：OpenClaw Assistant
;;; 日期：2026-01-21
;;; 
;;; 功能描述：
;;;   本插件提供一个集中化的插件管理解决方案，支持：
;;;   1. 集中管理所有插件加载路径
;;;   2. 主插件加载后自动加载配置的其他插件
;;;   3. 交互式配置界面（DCL 对话框）
;;;   4. 支持路径的增删改查操作
;;;   5. 显示插件名称、版本、描述等详细信息
;;;
;;; 兼容平台：
;;;   - AutoCAD 2014-2026
;;;   - 中望 CAD 2024-2026
;;;
;;; 使用方法：
;;;   1. 将本文件添加到 CAD 启动加载项
;;;   2. 运行命令 PLM 或 PLUGINLOADER 打开管理界面
;;;   3. 在对话框中配置插件路径
;;;   4. 插件会自动加载配置的路径中的所有 LISP 文件
;;;
;;; ============================================================================

;;; ----------------------------------------------------------------------------
;;; 系统变量定义
;;; ----------------------------------------------------------------------------
(vl-load-com) ; 加载 ActiveX 支持

;;; 全局变量
(setq *PluginLoader-Version* "1.0.0")
(setq *PluginLoader-ConfigFile* nil) ; 配置文件路径
(setq *PluginLoader-PluginList* nil) ; 插件列表
(setq *PluginLoader-LoadedList* nil) ; 已加载插件列表

;;; ----------------------------------------------------------------------------
;;; 辅助函数 - 获取配置文件路径
;;; ----------------------------------------------------------------------------
(defun PL:GetConfigPath ()
  "获取配置文件路径，优先使用用户目录，回退到插件目录"
  (setq *PluginLoader-ConfigFile*
    (strcat
      (if (and (boundp 'vla-get-Document)
               (setq *acad-doc* (vla-get-ActiveDocument (vlax-get-acad-object))))
        (vl-filename-directory (vla-get-FullName *acad-doc*))
        (getvar "ROAMABLEROOTPREFIX"))
      "\\PluginLoader\\PluginLoader.cfg"
    )
  )
  *PluginLoader-ConfigFile*
)

;;; ----------------------------------------------------------------------------
;;; 辅助函数 - 确保目录存在
;;; ----------------------------------------------------------------------------
(defun PL:EnsureDirectory (path / dir)
  "确保指定目录存在，不存在则创建"
  (setq dir (vl-filename-directory path))
  (if (not (findfile dir))
    (vl-mkdir dir)
  )
  T
)

;;; ----------------------------------------------------------------------------
;;; 配置文件读取函数
;;; ----------------------------------------------------------------------------
(defun PL:ReadConfig ( / file line lines section current-section parse-error)
  "读取配置文件，返回插件列表
   增强错误处理：
   - 配置文件不存在时自动创建
   - 配置文件损坏时跳过错误行
   - DCL 加载失败时提供回退方案"
  (setq *PluginLoader-PluginList* nil)
  (setq parse-error 0) ; 解析错误计数
  
  ;; 检查配置文件是否存在
  (if (not (findfile *PluginLoader-ConfigFile*))
    (progn
      (princ "\n配置文件不存在，将创建默认配置")
      (if (not (PL:CreateDefaultConfig))
        (progn
          (princ "\n错误：无法创建默认配置文件")
          (princ "\n请检查写入权限")
          nil
        )
      )
    )
  )
  
  ;; 尝试打开配置文件
  (setq file (open *PluginLoader-ConfigFile* "r"))
  (if file
    (progn
      (setq lines nil)
      (setq section nil)
      (setq current-section "Plugins") ; 默认段落
      
      ;; 逐行读取配置文件
      (while (setq line (read-line file))
        ;; 使用 vl-catch-all-apply 捕获可能的错误
        (vl-catch-all-apply
          '(lambda ()
             (setq line (vl-string-trim " \t\n\r" line))
             
             ;; 跳过空行和注释
             (if (and (/= line "")
                      (/= (substr line 1 1) ";")
                      (/= (substr line 1 1) "#"))
               (progn
                 ;; 检查是否为段落标记 [Section]
                 (if (= (substr line 1 1) "[")
                   (setq current-section (vl-string-trim "[]" line))
                   ;; 处理插件条目
                   (if (= current-section "Plugins")
                     (progn
                       ;; 解析插件配置行：Path|Name|Version|Description|Enabled
                       (setq parts (PL:SplitString line "|"))
                       (if (>= (length parts) 5)
                         (setq *PluginLoader-PluginList*
                           (append *PluginLoader-PluginList*
                             (list
                               (list
                                 (nth 0 parts) ; Path
                                 (nth 1 parts) ; Name
                                 (nth 2 parts) ; Version
                                 (nth 3 parts) ; Description
                                 (nth 4 parts) ; Enabled
                               )
                             )
                           )
                         )
                         ;; 格式错误，记录但不中断
                         (progn
                           (setq parse-error (1+ parse-error))
                           (princ (strcat "\n警告：跳过格式错误的配置行：" (substr line 1 50)))
                         )
                       )
                     )
                   )
                 )
               )
             )
           )
        )
      )
      (close file)
      
      ;; 报告解析错误
      (if (> parse-error 0)
        (princ (strcat "\n共跳过 " (itoa parse-error) " 行格式错误的配置"))
      )
    )
    (progn
      (princ (strcat "\n错误：无法打开配置文件 " *PluginLoader-ConfigFile*))
      (princ "\n请检查文件权限和路径")
      nil
    )
  )
  
  *PluginLoader-PluginList*
)

;;; ----------------------------------------------------------------------------
;;; 字符串分割函数
;;; ----------------------------------------------------------------------------
(defun PL:SplitString (str delim / pos result)
  "使用指定分隔符分割字符串"
  (setq result nil)
  (while (setq pos (vl-string-position delim str))
    (setq result (append result (list (substr str 1 pos))))
    (setq str (substr str (+ pos 2)))
  )
  (append result (list str))
)

;;; ----------------------------------------------------------------------------
;;; 配置文件写入函数
;;; ----------------------------------------------------------------------------
(defun PL:WriteConfig (plugin-list / file plugin write-error)
  "将插件列表写入配置文件
   增强错误处理：
   - 确保目录存在
   - 捕获写入错误
   - 提供详细的错误信息"
  (setq write-error nil)
  
  ;; 确保目录存在
  (if (not (PL:EnsureDirectory *PluginLoader-ConfigFile*))
    (progn
      (princ (strcat "\n错误：无法创建配置目录 " (vl-filename-directory *PluginLoader-ConfigFile*)))
      nil
    )
  )
  
  ;; 使用 vl-catch-all-apply 捕获写入错误
  (setq write-result
    (vl-catch-all-apply
      '(lambda ()
         (setq file (open *PluginLoader-ConfigFile* "w"))
         (if file
           (progn
             ;; 写入文件头
             (write-line "; PluginLoader 配置文件" file)
             (write-line "; 版本：1.0.0" file)
             (write-line "; 格式：Path|Name|Version|Description|Enabled" file)
             (write-line "; Enabled: 1=启用，0=禁用" file)
             (write-line (strcat "; 最后更新：" (rtos (getvar "CDATE") 2 0)) file)
             (write-line "")
             (write-line "[Plugins]" file)
             
             ;; 写入每个插件配置
             (foreach plugin plugin-list
               (write-line
                 (strcat
                   (nth 0 plugin) "|"
                   (nth 1 plugin) "|"
                   (nth 2 plugin) "|"
                   (nth 3 plugin) "|"
                   (nth 4 plugin)
                 )
                 file
               )
             )
             
             (close file)
             T
           )
           (progn
             (princ (strcat "\n错误：无法打开配置文件进行写入 " *PluginLoader-ConfigFile*))
             (princ "\n请检查文件权限")
             nil
           )
         )
       )
    )
  )
  
  ;; 检查是否有异常
  (if (vl-catch-all-error-p write-result)
    (progn
      (princ (strcat "\n错误：写入配置文件时发生异常"))
      (princ (strcat "\n  详情：" (vl-catch-all-error-message write-result)))
      nil
    )
    write-result
  )
)

;;; ----------------------------------------------------------------------------
;;; 创建默认配置文件
;;; ----------------------------------------------------------------------------
(defun PL:CreateDefaultConfig ()
  "创建默认配置文件"
  (PL:EnsureDirectory *PluginLoader-ConfigFile*)
  
  (setq file (open *PluginLoader-ConfigFile* "w"))
  (if file
    (progn
      (write-line "; PluginLoader 配置文件" file)
      (write-line "; 格式：Path|Name|Version|Description|Enabled" file)
      (write-line "; Enabled: 1=启用，0=禁用" file)
      (write-line "" file)
      (write-line "[Plugins]" file)
      (write-line "; 示例配置 - 请根据实际情况修改" file)
      (write-line "; C:\\CAD_Plugins\\MyTools.lsp|我的工具集|1.0|常用绘图工具|1" file)
      (close file)
      T
    )
  )
)

;;; ----------------------------------------------------------------------------
;;; 插件加载函数
;;; ----------------------------------------------------------------------------
(defun PL:LoadPlugins ( / plugin result load-error file-not-found)
  "加载所有启用的插件
   增强错误处理：
   - 文件不存在时显示详细提示
   - 加载失败时不影响其他插件
   - 统计错误数量"
  (setq *PluginLoader-LoadedList* nil)
  (setq result T)
  (setq load-error 0) ; 加载错误计数
  (setq file-not-found 0) ; 文件不存在计数
  
  (foreach plugin *PluginLoader-PluginList*
    (if (= (nth 4 plugin) "1") ; 检查是否启用
      (progn
        (setq path (nth 0 plugin))
        (setq name (nth 1 plugin))
        
        ;; 使用 vl-catch-all-apply 捕获加载错误
        (setq load-result
          (vl-catch-all-apply
            '(lambda ()
               ;; 检查文件是否存在
               (if (findfile path)
                 (progn
                   ;; 尝试加载插件
                   (if (load path)
                     (progn
                       (setq *PluginLoader-LoadedList*
                         (append *PluginLoader-LoadedList* (list name))
                       )
                       (princ (strcat "\n已加载插件：" name))
                       T
                     )
                     (progn
                       (princ (strcat "\n警告：加载插件失败 - " name " (" path ")"))
                       (setq load-error (1+ load-error))
                       nil
                     )
                   )
                 )
                 (progn
                   (princ (strcat "\n警告：插件文件不存在 - " path))
                   (setq file-not-found (1+ file-not-found))
                   nil
                 )
               )
             )
          )
        )
        
        ;; 检查是否有异常
        (if (vl-catch-all-error-p load-result)
          (progn
            (princ (strcat "\n错误：加载插件 " name " 时发生异常"))
            (princ (strcat "\n  详情：" (vl-catch-all-error-message load-result)))
            (setq load-error (1+ load-error))
          )
        )
      )
    )
  )
  
  ;; 报告加载统计
  (if *PluginLoader-LoadedList*
    (princ (strcat "\n\n成功加载 " (itoa (length *PluginLoader-LoadedList*)) " 个插件"))
  )
  (if (> file-not-found 0)
    (princ (strcat "\n文件不存在：" (itoa file-not-found) " 个"))
  )
  (if (> load-error 0)
    (princ (strcat "\n加载失败：" (itoa load-error) " 个"))
  )
  
  ;; 如果没有任何插件加载成功且有错误，返回 nil
  (if (and (or (> file-not-found 0) (> load-error 0))
           (not *PluginLoader-LoadedList*))
    nil
    T
  )
)

;;; ----------------------------------------------------------------------------
;;; 添加插件路径
;;; ----------------------------------------------------------------------------
(defun PL:AddPlugin (path name version description / plugin)
  "添加新的插件配置"
  (setq plugin (list path name version description "1"))
  (setq *PluginLoader-PluginList*
    (append *PluginLoader-PluginList* (list plugin))
  )
  (PL:WriteConfig *PluginLoader-PluginList*)
  T
)

;;; ----------------------------------------------------------------------------
;;; 删除插件路径
;;; ----------------------------------------------------------------------------
(defun PL:DeletePlugin (index / new-list)
  "根据索引删除插件配置"
  (if (and (>= index 0) (< index (length *PluginLoader-PluginList*)))
    (progn
      (setq new-list nil)
      (repeat index
        (setq new-list (append new-list (list (car *PluginLoader-PluginList*))))
        (setq *PluginLoader-PluginList* (cdr *PluginLoader-PluginList*))
      )
      (setq *PluginLoader-PluginList* (cdr *PluginLoader-PluginList*))
      (setq *PluginLoader-PluginList* (append new-list *PluginLoader-PluginList*))
      (PL:WriteConfig *PluginLoader-PluginList*)
      T
    )
    nil
  )
)

;;; ----------------------------------------------------------------------------
;;; 修改插件配置
;;; ----------------------------------------------------------------------------
(defun PL:ModifyPlugin (index path name version description / plugin new-list i)
  "修改指定索引的插件配置"
  (if (and (>= index 0) (< index (length *PluginLoader-PluginList*)))
    (progn
      (setq plugin (list path name version description (nth 4 (nth index *PluginLoader-PluginList*))))
      (setq new-list nil)
      (setq i 0)
      
      (foreach item *PluginLoader-PluginList*
        (if (= i index)
          (setq new-list (append new-list (list plugin)))
          (setq new-list (append new-list (list item)))
        )
        (setq i (1+ i))
      )
      
      (setq *PluginLoader-PluginList* new-list)
      (PL:WriteConfig *PluginLoader-PluginList*)
      T
    )
    nil
  )
)

;;; ----------------------------------------------------------------------------
;;; 切换插件启用状态
;;; ----------------------------------------------------------------------------
(defun PL:TogglePlugin (index / new-list i item)
  "切换指定索引插件的启用状态"
  (if (and (>= index 0) (< index (length *PluginLoader-PluginList*)))
    (progn
      (setq new-list nil)
      (setq i 0)
      
      (foreach item *PluginLoader-PluginList*
        (if (= i index)
          (setq new-list
            (append new-list
              (list
                (list
                  (nth 0 item)
                  (nth 1 item)
                  (nth 2 item)
                  (nth 3 item)
                  (if (= (nth 4 item) "1") "0" "1")
                )
              )
            )
          )
          (setq new-list (append new-list (list item)))
        )
        (setq i (1+ i))
      )
      
      (setq *PluginLoader-PluginList* new-list)
      (PL:WriteConfig *PluginLoader-PluginList*)
      T
    )
    nil
  )
)

;;; ----------------------------------------------------------------------------
;;; DCL 对话框函数
;;; ----------------------------------------------------------------------------
(defun PL:ShowDialog ( / dcl-id dialog-result)
  "显示插件管理对话框"
  
  ;; 加载 DCL 文件
  (setq dcl-id (load_dialog "PluginLoader.dcl"))
  
  (if (< dcl-id 0)
    (progn
      (princ "\n错误：无法加载对话框文件 PluginLoader.dcl")
      (princ "\n请确保 PluginLoader.dcl 文件在 CAD 支持路径中")
      nil
    )
    (progn
      ;; 显示对话框
      (if (not (new_dialog "PluginLoader" dcl-id))
        (progn
          (princ "\n错误：无法创建对话框")
          (unload_dialog dcl-id)
          nil
        )
        (progn
          ;; 初始化对话框内容
          (PL:InitDialog)
          
          ;; 设置动作函数
          (action_tile "accept" "(PL:DialogAccept)")
          (action_tile "cancel" "(done_dialog 0)")
          (action_tile "add_btn" "(PL:DialogAdd)")
          (action_tile "edit_btn" "(PL:DialogEdit)")
          (action_tile "delete_btn" "(PL:DialogDelete)")
          (action_tile "toggle_btn" "(PL:DialogToggle)")
          (action_tile "reload_btn" "(PL:DialogReload)")
          (action_tile "help_btn" "(PL:ShowHelp)")
          
          ;; 设置列表选择处理 - 单击显示信息，双击切换启用状态
          (action_tile "plugin_list"
            "(if (= $event \\\"\\\"double\\\"\\\")
               (PL:DialogToggle)
               (PL:DialogSelect)
             )"
          )
          
          ;; 显示对话框并等待用户操作
          (setq dialog-result (start_dialog))
          
          ;; 卸载对话框
          (unload_dialog dcl-id)
          
          ;; 如果用户点击确定，重新加载插件
          (if (= dialog-result 1)
            (PL:LoadPlugins)
          )
          
          dialog-result
        )
      )
    )
  )
)

;;; ----------------------------------------------------------------------------
;;; 对话框初始化
;;; ----------------------------------------------------------------------------
(defun PL:InitDialog ( / i item)
  "初始化对话框列表内容"
  ;; 填充插件列表
  (setq i 0)
  (foreach item *PluginLoader-PluginList*
    (add_list
      (strcat
        (nth 1 item) "\t"      ; 名称
        (nth 2 item) "\t"      ; 版本
        (if (= (nth 4 item) "1") "启用" "禁用") "\t"  ; 状态
        (nth 3 item)           ; 描述
      )
    )
    (setq i (1+ i))
  )
)

;;; ----------------------------------------------------------------------------
;;; 对话框回调函数
;;; ----------------------------------------------------------------------------
(defun PL:DialogAccept ()
  "对话框确定按钮处理"
  (done_dialog 1)
)

(defun PL:DialogAdd ( / dcl-id result path name version desc)
  "对话框添加按钮处理 - 打开添加插件对话框"
  
  ;; 加载 DCL 文件
  (setq dcl-id (load_dialog "PluginLoader.dcl"))
  
  (if (< dcl-id 0)
    (progn
      (alert "错误：无法加载对话框文件")
      nil
    )
    (progn
      ;; 创建添加对话框
      (if (not (new_dialog "PluginLoader_Add" dcl-id))
        (progn
          (alert "错误：无法创建添加对话框")
          (unload_dialog dcl-id)
          nil
        )
        (progn
          ;; 设置默认值
          (set_tile "path_edit" "")
          (set_tile "name_edit" "")
          (set_tile "version_edit" "1.0")
          (set_tile "desc_edit" "")
          
          ;; 设置浏览按钮动作
          (action_tile "browse_btn" "(PL:BrowseFile \"path_edit\")")
          
          ;; 设置确定按钮动作
          (action_tile "accept"
            "(setq result 1) (done_dialog 1)"
          )
          
          ;; 设置取消按钮动作
          (action_tile "cancel"
            "(setq result 0) (done_dialog 0)"
          )
          
          ;; 显示添加对话框
          (start_dialog)
          (unload_dialog dcl-id)
          
          ;; 如果用户点击确定，添加插件
          (if (= result 1)
            (progn
              ;; 获取输入值
              (setq path (get_tile "path_edit"))
              (setq name (get_tile "name_edit"))
              (setq version (get_tile "version_edit"))
              (setq desc (get_tile "desc_edit"))
              
              ;; 验证必填字段
              (if (or (= path "") (= name ""))
                (progn
                  (alert "错误：插件路径和名称不能为空")
                  nil
                )
                (progn
                  ;; 检查文件是否存在
                  (if (not (findfile path))
                    (progn
                      (if (= (alert (strcat "警告：文件不存在\n" path "\n\n是否仍然保存？" "12")) "2")
                        (progn
                          ;; 用户选择否，不添加
                          nil
                        )
                      )
                    )
                  )
                  
                  ;; 如果版本号为空，使用默认值
                  (if (= version "")
                    (setq version "1.0")
                  )
                  
                  ;; 如果描述为空，使用默认值
                  (if (= desc "")
                    (setq desc "用户添加的插件")
                  )
                  
                  ;; 添加插件到配置
                  (PL:AddPlugin path name version desc)
                  
                  ;; 刷新列表显示
                  (start_list "plugin_list")
                  (end_list)
                  (PL:InitDialog)
                  
                  (princ (strcat "\n已添加插件：" name))
                )
              )
            )
          )
        )
      )
    )
  )
)

(defun PL:DialogEdit ( / sel item dcl-id result path name version desc enabled)
  "对话框编辑按钮处理 - 打开编辑对话框并保存修改"
  (setq sel (get_tile "plugin_list"))
  
  ;; 检查是否选择了插件
  (if (or (= sel "") (= (atoi sel) -1))
    (progn
      (alert "请先选择要编辑的插件")
      nil
    )
    (progn
      ;; 获取选中的插件信息
      (setq item (nth (atoi sel) *PluginLoader-PluginList*))
      (if (not item)
        (progn
          (alert "无法获取插件信息")
          nil
        )
        (progn
          ;; 提取插件信息
          (setq path (nth 0 item))
          (setq name (nth 1 item))
          (setq version (nth 2 item))
          (setq desc (nth 3 item))
          (setq enabled (nth 4 item))
          
          ;; 加载编辑对话框
          (setq dcl-id (load_dialog "PluginLoader.dcl"))
          (if (< dcl-id 0)
            (progn
              (alert "错误：无法加载对话框文件")
              nil
            )
            (progn
              ;; 创建编辑对话框
              (if (not (new_dialog "PluginLoader_Edit" dcl-id))
                (progn
                  (alert "错误：无法创建编辑对话框")
                  (unload_dialog dcl-id)
                  nil
                )
                (progn
                  ;; 填充当前值到编辑框
                  (set_tile "path_edit" path)
                  (set_tile "name_edit" name)
                  (set_tile "version_edit" version)
                  (set_tile "desc_edit" desc)
                  (set_tile "enabled_toggle" enabled)
                  
                  ;; 设置浏览按钮动作
                  (action_tile "browse_btn" "(PL:BrowseFile \"path_edit\")")
                  
                  ;; 设置确定按钮动作 - 保存修改
                  (action_tile "accept"
                    "(setq result 1) (done_dialog 1)"
                  )
                  
                  ;; 设置取消按钮动作
                  (action_tile "cancel"
                    "(setq result 0) (done_dialog 0)"
                  )
                  
                  ;; 显示编辑对话框
                  (start_dialog)
                  (unload_dialog dcl-id)
                  
                  ;; 如果用户点击确定，保存修改
                  (if (= result 1)
                    (progn
                      ;; 获取修改后的值
                      (setq new-path (get_tile "path_edit"))
                      (setq new-name (get_tile "name_edit"))
                      (setq new-version (get_tile "version_edit"))
                      (setq new-desc (get_tile "desc_edit"))
                      (setq new-enabled (get_tile "enabled_toggle"))
                      
                      ;; 验证必填字段
                      (if (or (= new-path "") (= new-name ""))
                        (progn
                          (alert "错误：插件路径和名称不能为空")
                          nil
                        )
                        (progn
                          ;; 检查文件是否存在
                          (if (not (findfile new-path))
                            (progn
                              (if (= (alert (strcat "警告：文件不存在\n" new-path "\n\n是否仍然保存？" "12")) "1")
                                nil
                                nil
                              )
                            )
                          )
                          
                          ;; 保存修改到配置
                          (PL:ModifyPlugin (atoi sel) new-path new-name new-version new-desc)
                          
                          ;; 如果启用状态改变，更新状态
                          (if (/= new-enabled enabled)
                            (progn
                              (setq new-item (nth (atoi sel) *PluginLoader-PluginList*))
                              (setq final-item (list (nth 0 new-item) (nth 1 new-item) (nth 2 new-item) (nth 3 new-item) new-enabled))
                              (setq new-list nil)
                              (setq i 0)
                              (foreach itm *PluginLoader-PluginList*
                                (if (= i (atoi sel))
                                  (setq new-list (append new-list (list final-item)))
                                  (setq new-list (append new-list (list itm)))
                                )
                                (setq i (1+ i))
                              )
                              (setq *PluginLoader-PluginList* new-list)
                              (PL:WriteConfig *PluginLoader-PluginList*)
                            )
                          )
                          
                          ;; 刷新列表显示
                          (start_list "plugin_list")
                          (end_list)
                          (PL:InitDialog)
                          
                          (princ (strcat "\n已更新插件：" new-name))
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

(defun PL:DialogDelete ()
  "对话框删除按钮处理"
  (setq sel (get_tile "plugin_list"))
  (if (/= sel "")
    (progn
      (if (= (atoi sel) -1)
        (princ "\n请先选择要删除的插件")
        (progn
          (PL:DeletePlugin (atoi sel))
          (start_list "plugin_list")
          (end_list)
          (PL:InitDialog)
        )
      )
    )
  )
)

(defun PL:DialogToggle ()
  "对话框切换启用状态按钮处理"
  (setq sel (get_tile "plugin_list"))
  (if (/= sel "")
    (progn
      (if (= (atoi sel) -1)
        (princ "\n请先选择要切换的插件")
        (progn
          (PL:TogglePlugin (atoi sel))
          (start_list "plugin_list")
          (end_list)
          (PL:InitDialog)
        )
      )
    )
  )
)

(defun PL:DialogReload ()
  "对话框重新加载按钮处理"
  (PL:ReadConfig)
  (start_list "plugin_list")
  (end_list)
  (PL:InitDialog)
  (princ "\n配置已重新加载")
)

(defun PL:DialogSelect ()
  "对话框列表选择处理"
  ;; 可用于显示详细信息
  (setq sel (get_tile "plugin_list"))
  (if (/= sel "")
    (progn
      (setq item (nth (atoi sel) *PluginLoader-PluginList*))
      (if item
        (princ (strcat "\n选中插件：" (nth 1 item) " - " (nth 3 item)))
      )
    )
  )
)

;;; ----------------------------------------------------------------------------
;;; 帮助功能 - 显示帮助对话框
;;; ----------------------------------------------------------------------------
(defun PL:ShowHelp ( / dcl-id)
  "显示帮助对话框 - 提供基本使用说明"
  
  ;; 加载 DCL 文件
  (setq dcl-id (load_dialog "PluginLoader.dcl"))
  
  (if (< dcl-id 0)
    (progn
      ;; DCL 加载失败时，使用命令行显示帮助
      (princ "\n\n=== PluginLoader 帮助信息 ===")
      (princ "\n版本：1.0.0")
      (princ "\n\n功能说明：")
      (princ "\n  • 集中管理所有 CAD 插件加载路径")
      (princ "\n  • 自动加载配置的插件")
      (princ "\n  • 支持插件的启用/禁用")
      (princ "\n  • 显示插件详细信息")
      (princ "\n\n使用方法：")
      (princ "\n  1. 输入 PLM 命令打开管理界面")
      (princ "\n  2. 点击'添加'按钮选择插件文件")
      (princ "\n  3. 使用'启用/禁用'控制插件加载")
      (princ "\n  4. 点击'确定'保存并重新加载")
      (princ "\n  5. 双击插件可快速切换启用状态")
      (princ "\n\n兼容平台：AutoCAD 2014-2026, 中望 CAD 2024-2026")
      (princ "\n==============================\n")
      nil
    )
    (progn
      ;; 创建帮助对话框
      (if (not (new_dialog "PluginLoader_Help" dcl-id))
        (progn
          (princ "\n错误：无法创建帮助对话框")
          (unload_dialog dcl-id)
          nil
        )
        (progn
          ;; 设置确定按钮动作
          (action_tile "accept" "(done_dialog 1)")
          
          ;; 显示帮助对话框
          (start_dialog)
          
          ;; 卸载对话框
          (unload_dialog dcl-id)
        )
      )
    )
  )
)

;;; ----------------------------------------------------------------------------
;;; 文件浏览功能 - 打开文件选择对话框
;;; ----------------------------------------------------------------------------
(defun PL:BrowseFile (edit-key / file-path file-name)
  "打开文件选择对话框，并将选中的路径填充到指定编辑框"
  ;; edit-key: 目标编辑框的键名（如 "path_edit"）
  
  ;; 打开文件选择对话框
  (setq file-path (getfiled "选择插件文件" "" "lsp;fas;vlx;arx;dll" 8))
  
  (if file-path
    (progn
      ;; 将路径填充到编辑框
      (set_tile edit-key file-path)
      
      ;; 自动提取文件名作为插件名称（如果名称框为空）
      (setq file-name (vl-filename-base file-path))
      
      ;; 尝试获取当前名称框的值
      (setq current-name (get_tile "name_edit"))
      
      ;; 如果名称框为空或为默认值，自动填充
      (if (or (= current-name "") (= current-name "1.0"))
        (set_tile "name_edit" file-name)
      )
      
      (princ (strcat "\n已选择：" file-path))
    )
    (princ "\n未选择文件")
  )
)

;;; ----------------------------------------------------------------------------
;;; 命令定义
;;; ----------------------------------------------------------------------------
(defun C:PLM ()
  "PluginLoader Manager - 打开插件管理界面"
  (PL:Main)
)

(defun C:PLUGINLOADER ()
  "PluginLoader - 打开插件管理界面（完整命令）"
  (PL:Main)
)

(defun C:PLR ()
  "PluginLoader Reload - 重新加载所有插件"
  (PL:ReadConfig)
  (PL:LoadPlugins)
  (princ)
)

;;; ----------------------------------------------------------------------------
;;; 主函数
;;; ----------------------------------------------------------------------------
(defun PL:Main ( / )
  "主入口函数"
  (princ (strcat "\nPluginLoader v" *PluginLoader-Version*))
  
  ;; 获取配置文件路径
  (PL:GetConfigPath)
  
  ;; 读取配置
  (PL:ReadConfig)
  
  ;; 显示管理对话框
  (PL:ShowDialog)
  
  (princ)
)

;;; ----------------------------------------------------------------------------
;;; 自动加载 - 当文件被加载时自动执行
;;; ----------------------------------------------------------------------------
(defun PL:AutoLoad ( / )
  "自动加载函数，在插件加载时执行"
  (PL:GetConfigPath)
  (PL:ReadConfig)
  (PL:LoadPlugins)
)

;; 启动自动加载
(PL:AutoLoad)

;;; ----------------------------------------------------------------------------
;;; 程序结束
;;; ----------------------------------------------------------------------------
(princ (strcat "\nPluginLoader v" *PluginLoader-Version* " 已加载。输入 PLM 打开管理界面。"))
(princ)

;;; ============================================================================
;;; 结束
;;; ============================================================================

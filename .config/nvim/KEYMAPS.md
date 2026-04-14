# Neovim 快捷键速查

基于当前仓库配置 + 当前本机已安装的 AstroNvim 默认映射整理。

- `<leader>` = `Space`（`init.lua:3`）
- `<localleader>` = `,`（`init.lua:4`）
- 默认启用 autosave：在 `InsertLeave`、`BufLeave`、`FocusLost` 时自动保存普通文件 buffer
- `Scope` 说明：
  - `Global`：全局可用
  - `Filetype`：仅特定语言 buffer 生效
  - `Neo-tree`：仅文件树窗口生效
  - `Terminal`：仅终端 buffer 生效
- `Source` 分两类：
  - `Custom`：你仓库里显式定义的映射
  - `Default`：当前 AstroNvim / AstroCore 默认映射，且未被你本地配置覆盖

## 1. 你自己的自定义快捷键

### 1.1 文件 / Buffer / 查找

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader><leader>` | 搜索文件 | Global | `lua/plugins/astrocore.lua:37` |
| `]b` | 下一个 buffer | Global | `lua/plugins/astrocore.lua:41` |
| `[b` | 上一个 buffer | Global | `lua/plugins/astrocore.lua:42` |
| `<leader>bd` | 从 tabline 选择并关闭 buffer | Global | `lua/plugins/astrocore.lua:43` |
| `<leader>bn` | 新建 buffer | Global | `lua/plugins/astrocore.lua:51` |
| `<leader>ff` | 查找文件 | Global | `lua/plugins/astrocore.lua:52` |
| `<leader>fg` | 全文搜索 | Global | `lua/plugins/astrocore.lua:56` |
| `<leader>fr` | 最近文件 | Global | `lua/plugins/astrocore.lua:60` |
| `<leader>fs` | 工作区 symbols | Global | `lua/plugins/astrocore.lua:64` |
| `<leader>fd` | 当前 buffer diagnostics | Global | `lua/plugins/astrocore.lua:68` |
| `<leader>tt` | 浮动终端 | Global | `lua/plugins/astrocore.lua:87` |

### 1.2 LSP

| Key | Action | Scope | Source |
|---|---|---|---|
| `gD` | 跳到 declaration | Global | `lua/plugins/astrolsp.lua:111` |
| `gd` | 跳到 definition | Global | `lua/plugins/astrolsp.lua:116` |
| `gi` | 跳到 implementation | Global | `lua/plugins/astrolsp.lua:121` |
| `gr` | 查看 references | Global | `lua/plugins/astrolsp.lua:126` |
| `gy` | 跳到 type definition | Global | `lua/plugins/astrolsp.lua:131` |
| `<leader>cr` | 重命名 symbol | Global | `lua/plugins/astrolsp.lua:136` |
| `<leader>ca` | Code action | Global | `lua/plugins/astrolsp.lua:141` |
| `K` | Hover 文档 | Global | `lua/plugins/astrolsp.lua:146` |
| `<leader>uY` | 切换当前 buffer 的 semantic tokens 高亮 | Global | `lua/plugins/astrolsp.lua:151` |

### 1.3 DAP 调试

| Key | Action | Scope | Source |
|---|---|---|---|
| `<F5>` | 继续 / 启动调试 | Global | `lua/plugins/dap.lua:24` |
| `<F6>` | 运行上次配置 | Global | `lua/plugins/dap.lua:25` |
| `<F10>` | Step over | Global | `lua/plugins/dap.lua:26` |
| `<F11>` | Step into | Global | `lua/plugins/dap.lua:27` |
| `<F12>` | Step out | Global | `lua/plugins/dap.lua:28` |
| `<leader>db` | 切换断点 | Global | `lua/plugins/dap.lua:29` |
| `<leader>dB` | 条件断点 | Global | `lua/plugins/dap.lua:30` |
| `<leader>dr` | 重启调试会话 | Global | `lua/plugins/dap.lua:31` |
| `<leader>dx` | 终止调试会话 | Global | `lua/plugins/dap.lua:32` |
| `<leader>de` | 评估变量 | Global | `lua/plugins/dap.lua:33` |

### 1.4 Harpoon

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>ha` | 添加当前文件到 Harpoon | Global | `lua/plugins/harpoon.lua:10` |
| `<leader>hh` | 打开 Harpoon 菜单 | Global | `lua/plugins/harpoon.lua:13` |
| `<leader>h1` | 跳到 Harpoon 文件 1 | Global | `lua/plugins/harpoon.lua:19` |
| `<leader>h2` | 跳到 Harpoon 文件 2 | Global | `lua/plugins/harpoon.lua:19` |
| `<leader>h3` | 跳到 Harpoon 文件 3 | Global | `lua/plugins/harpoon.lua:19` |
| `<leader>h4` | 跳到 Harpoon 文件 4 | Global | `lua/plugins/harpoon.lua:19` |
| `<leader>h5` | 跳到 Harpoon 文件 5 | Global | `lua/plugins/harpoon.lua:19` |

### 1.5 Flash

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>fw` | Flash word jump | Global | `lua/plugins/flash.lua:10` |
| `<leader>fc` | Flash char search | Global | `lua/plugins/flash.lua:22` |

### 1.6 AI 补全 / Trae

| Key | Action | Scope | Source |
|---|---|---|---|
| `→` | 采纳 Trae 建议；无建议时保留原右移行为 | Insert / 支持的文件类型 | `lua/plugins/trae.lua:12` |
| `<C-l>` | 采纳 Trae 建议；无建议时走原有 fallback | Insert / 支持的文件类型 | `lua/plugins/trae.lua:13` |
| `:Trae login` | 登录 Trae | Global | `lua/plugins/trae.lua:6` |
| `:Trae status` | 检查 Trae 当前 buffer 状态 | Global | `lua/plugins/trae.lua:6` |

> 说明：Trae 不再接管 `<Tab>`；`<Tab>` 继续留给 blink/snippet 补全链路。Trae 只在其支持的文件类型中生效，例如 `go`、`python`、`java`、`lua`、`javascript`、`typescript`、`rust`，不支持 `thrift`。

### 1.7 Cloud Dev

> 说明：当前实现已对接本机 `cloudide-cli`，并支持按当前 git 项目自动匹配 CloudIDE workspace。推荐主入口是 `:CloudDevAttach`：优先读取本地绑定，必要时自动匹配或弹出选择，若 workspace 未启动则自动 start 后再连接。UI 目前是轻量方案：`vim.ui.select` + 浮动终端，还不是完整 TUI 面板。

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>cA` | 按当前项目自动 attach CloudIDE workspace | Global | `lua/plugins/astrocore.lua:73` |
| `<leader>cB` | 为当前项目绑定 CloudIDE workspace | Global | `lua/plugins/astrocore.lua:74` |
| `<leader>cE` | 手动选择当前 session 的 CloudIDE workspace | Global | `lua/plugins/astrocore.lua:75` |
| `<leader>cS` | 查看 Cloud Dev 状态 | Global | `lua/plugins/astrocore.lua:76` |
| `<leader>cU` | 解绑当前项目的 CloudIDE workspace | Global | `lua/plugins/astrocore.lua:77` |
| `:CloudDevStatus` | 查看 Cloud Dev CLI 可用性与当前 session 选中的 workspace | Global | `lua/plugins/clouddev.lua:482` |
| `:CloudDevList` | 在浮动终端中查看 CloudIDE workspace 列表原始输出 | Global | `lua/plugins/clouddev.lua:486` |
| `:CloudDevSelect` | 使用 `vim.ui.select` 手动选择当前 session 的 CloudIDE workspace | Global | `lua/plugins/clouddev.lua:496` |
| `:CloudDevEnter` | 在浮动终端通过 SSH 进入当前 session 选中的 CloudIDE workspace | Global | `lua/plugins/clouddev.lua:506` |
| `:CloudDevAttach` | 自动匹配/绑定/启动并连接当前项目对应的 CloudIDE workspace | Global | `lua/plugins/clouddev.lua:522` |
| `:CloudDevBind` | 手动为当前 git 项目绑定 CloudIDE workspace | Global | `lua/plugins/clouddev.lua:533` |
| `:CloudDevUnbind` | 清除当前 git 项目的 CloudIDE workspace 绑定 | Global | `lua/plugins/clouddev.lua:550` |

### 1.8 文件类型专属

#### Python

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>pr` | 调试当前 method | Python | `ftplugin/python.lua:3` |
| `<leader>pR` | 调试当前 class | Python | `ftplugin/python.lua:4` |
| `<leader>pf` | 调试选中内容 | Python | `ftplugin/python.lua:5` |
| `<leader>pi` | Organize imports | Python | `ftplugin/python.lua:7` |

#### Go

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>gt` | 调试当前 test | Go | `ftplugin/go.lua:3` |
| `<leader>gT` | 调试上一次 test | Go | `ftplugin/go.lua:4` |
| `<leader>gi` | Organize imports | Go | `ftplugin/go.lua:6` |

#### Java

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>jo` | Java organize imports | Java | `ftplugin/java.lua:60` |
| `<leader>jv` | Java extract variable | Java | `ftplugin/java.lua:61` |
| `<leader>jc` | Java extract constant | Java | `ftplugin/java.lua:62` |
| `<leader>jt` | 测试最近方法 | Java | `ftplugin/java.lua:63` |
| `<leader>jT` | 测试整个类 | Java | `ftplugin/java.lua:64` |
| `<leader>ju` | 更新项目配置 | Java | `ftplugin/java.lua:65` |
| `<leader>jr` | 刷新 debug 配置 | Java | `ftplugin/java.lua:66` |

## 2. 仍然生效的 AstroNvim / AstroCore 默认快捷键

以下内容来自你当前安装版本：

- `AstroNvim`：`lazy-lock.json:2`
- `astrocore`：`lazy-lock.json:5`
- `astrolsp`：`lazy-lock.json:6`

以及默认映射定义：

- `~/.local/share/nvim/lazy/AstroNvim/lua/astronvim/plugins/_astrocore_mappings.lua`
- `~/.local/share/nvim/lazy/AstroNvim/lua/astronvim/plugins/_astrolsp_mappings.lua`
- `~/.local/share/nvim/lazy/AstroNvim/lua/astronvim/plugins/neo-tree.lua`
- `~/.local/share/nvim/lazy/AstroNvim/lua/astronvim/plugins/toggleterm.lua`

### 2.1 基础编辑 / 注释 / 分屏

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>q` | 关闭当前窗口 | Global | `_astrocore_mappings.lua:33` |
| `<leader>Q` | 退出 AstroNvim | Global | `_astrocore_mappings.lua:34` |
| `<leader>n` | 新建文件 | Global | `_astrocore_mappings.lua:35` |
| `<C-S>` | 强制写入 | Global | `_astrocore_mappings.lua:36` |
| `<C-Q>` | 强制退出 | Global | `_astrocore_mappings.lua:38` |
| `|` | 垂直分屏 | Global | `_astrocore_mappings.lua:39` |
| `\` | 水平分屏 | Global | `_astrocore_mappings.lua:40` |
| `<leader>/` | 切换当前行注释 | Normal / Visual | `_astrocore_mappings.lua:41` |
| `gco` | 在下方插入注释行 | Global | `_astrocore_mappings.lua:44` |
| `gcO` | 在上方插入注释行 | Global | `_astrocore_mappings.lua:45` |
| `<leader>R` | 重命名当前文件 | Global | `_astrocore_mappings.lua:47` |
| `<Tab>` | 右缩进并保持选区 | Visual | `_astrocore_mappings.lua:155` |
| `<S-Tab>` | 左缩进并保持选区 | Visual | `_astrocore_mappings.lua:154` |

### 2.2 Buffer 管理

> 你已覆盖 `]b`、`[b`、`<leader>bd`、`<leader>bn`，以下是其余仍可能使用的默认映射。

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>c` | 关闭当前 buffer | Global | `_astrocore_mappings.lua:71` |
| `<leader>C` | 强制关闭当前 buffer | Global | `_astrocore_mappings.lua:72` |
| `>b` | 向右移动 buffer tab | Global | `_astrocore_mappings.lua:81` |
| `<b` | 向左移动 buffer tab | Global | `_astrocore_mappings.lua:85` |
| `<leader>b` | Buffers 分组 | Global | `_astrocore_mappings.lua:90` |
| `<leader>bc` | 关闭其他 buffer | Global | `_astrocore_mappings.lua:91` |
| `<leader>bC` | 关闭全部 buffer | Global | `_astrocore_mappings.lua:93` |
| `<leader>bl` | 关闭左侧所有 buffer | Global | `_astrocore_mappings.lua:94` |
| `<leader>bp` | 切到上一个 buffer | Global | `_astrocore_mappings.lua:96` |
| `<leader>br` | 关闭右侧所有 buffer | Global | `_astrocore_mappings.lua:97` |
| `<leader>bs` | Buffer 排序分组 | Global | `_astrocore_mappings.lua:99` |
| `<leader>bse` | 按扩展名排序 buffer | Global | `_astrocore_mappings.lua:100` |
| `<leader>bsr` | 按相对路径排序 buffer | Global | `_astrocore_mappings.lua:101` |
| `<leader>bsp` | 按完整路径排序 buffer | Global | `_astrocore_mappings.lua:102` |
| `<leader>bsi` | 按 buffer 编号排序 | Global | `_astrocore_mappings.lua:103` |
| `<leader>bsm` | 按修改状态排序 | Global | `_astrocore_mappings.lua:104` |

### 2.3 LSP / Diagnostics 默认组

> 你已覆盖 `gD`、`gd`、`gy`、`<leader>uY` 等，以下是补充项。

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>l` | Language Tools 分组 | Global | `_astrolsp_mappings.lua:7` |
| `<leader>la` | LSP code action | Global / Visual | `_astrolsp_mappings.lua:10` |
| `<leader>lA` | LSP source action | Global | `_astrolsp_mappings.lua:14` |
| `<leader>ll` | 刷新 CodeLens | Global | `_astrolsp_mappings.lua:21` |
| `<leader>lL` | 执行 CodeLens | Global | `_astrolsp_mappings.lua:32` |
| `<leader>uL` | 切换 CodeLens | Global | `_astrolsp_mappings.lua:34` |
| `<leader>lf` | 格式化当前 buffer | Global | `_astrolsp_mappings.lua:59` |
| `<leader>uf` | 切换当前 buffer 自动格式化 | Global | `_astrolsp_mappings.lua:69` |
| `<leader>uF` | 切换全局自动格式化 | Global | `_astrolsp_mappings.lua:74` |
| `<leader>u?` | 切换自动 signature help | Global | `_astrolsp_mappings.lua:80` |
| `<leader>uh` | 切换当前 buffer inlay hints | Global | `_astrolsp_mappings.lua:86` |
| `<leader>uH` | 切换全局 inlay hints | Global | `_astrolsp_mappings.lua:91` |
| `<leader>lR` | 搜索 references | Global | `_astrolsp_mappings.lua:97` |
| `<leader>lr` | 重命名当前 symbol | Global | `_astrolsp_mappings.lua:100` |
| `<leader>lh` | Signature help | Global | `_astrolsp_mappings.lua:103` |
| `gK` | Signature help | Global | `_astrolsp_mappings.lua:105` |
| `<leader>lG` | 搜索 workspace symbols | Global | `_astrolsp_mappings.lua:114` |
| `<leader>lw` | Workspace diagnostics | Global | `_astrolsp_mappings.lua:119` |
| `<leader>li` | LSP 信息 / health | Global | `_astrocore_mappings.lua:107` |
| `<leader>ld` | 悬浮显示 diagnostics | Global | `_astrocore_mappings.lua:108` |
| `gl` | 悬浮显示 diagnostics | Global | `_astrocore_mappings.lua:121` |
| `[e` | 上一个 error | Global | `_astrocore_mappings.lua:117` |
| `]e` | 下一个 error | Global | `_astrocore_mappings.lua:118` |
| `[w` | 上一个 warning | Global | `_astrocore_mappings.lua:119` |
| `]w` | 下一个 warning | Global | `_astrocore_mappings.lua:120` |

### 2.4 Explorer / Neo-tree

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>e` | 打开 / 切换文件树 | Global | `neo-tree.lua:10` |
| `<leader>o` | 聚焦 / 返回文件树 | Global | `neo-tree.lua:11` |
| `[b` | 上一个 source | Neo-tree | `neo-tree.lua:174` |
| `]b` | 下一个 source | Neo-tree | `neo-tree.lua:175` |
| `h` | 返回父节点 / 折叠节点 | Neo-tree | `neo-tree.lua:178` |
| `l` | 进入子节点 / 打开文件 | Neo-tree | `neo-tree.lua:179` |
| `O` | 系统打开 | Neo-tree | `neo-tree.lua:176` |
| `<S-CR>` | 系统打开 | Neo-tree | `neo-tree.lua:172` |
| `Y` | 复制路径/文件名等 | Neo-tree | `neo-tree.lua:177` |

### 2.5 Terminal / ToggleTerm

> 你已把 `<leader>tt` 覆盖为自定义浮动终端；默认终端组里还有很多键仍可用。

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>t` | Terminal 分组 | Global | `toggleterm.lua:10` |
| `<leader>tf` | 浮动终端 | Global | `toggleterm.lua:48` |
| `<leader>th` | 水平终端 | Global | `toggleterm.lua:49` |
| `<leader>tv` | 垂直终端 | Global | `toggleterm.lua:51` |
| `<leader>tl` | LazyGit 浮动终端 | Global | `toggleterm.lua:23` |
| `<leader>gg` | LazyGit 浮动终端 | Global | `toggleterm.lua:22` |
| `<leader>tn` | Node 终端 | Global | `toggleterm.lua:26` |
| `<leader>tp` | Python 终端 | Global | `toggleterm.lua:46` |
| `<leader>tu` | gdu 终端 | Global | `toggleterm.lua:37` |
| `<F7>` | 切换终端 | Normal / Insert / Terminal | `toggleterm.lua:52` |
| `<C-'>` | 切换终端 | Normal / Insert / Terminal | `toggleterm.lua:55` |
| `<C-H>` | 终端窗口向左跳转 | Terminal | `_astrocore_mappings.lua:167` |
| `<C-J>` | 终端窗口向下跳转 | Terminal | `_astrocore_mappings.lua:168` |
| `<C-K>` | 终端窗口向上跳转 | Terminal | `_astrocore_mappings.lua:169` |
| `<C-L>` | 终端窗口向右跳转 | Terminal | `_astrocore_mappings.lua:170` |

### 2.6 分屏 / Tab / 列表

| Key | Action | Scope | Source |
|---|---|---|---|
| `<C-H>` | 跳到左侧分屏 | Global | `_astrocore_mappings.lua:128` |
| `<C-J>` | 跳到下方分屏 | Global | `_astrocore_mappings.lua:129` |
| `<C-K>` | 跳到上方分屏 | Global | `_astrocore_mappings.lua:130` |
| `<C-L>` | 跳到右侧分屏 | Global | `_astrocore_mappings.lua:131` |
| `<C-Up>` | 缩小上方分屏高度 | Global | `_astrocore_mappings.lua:132` |
| `<C-Down>` | 增大下方分屏高度 | Global | `_astrocore_mappings.lua:133` |
| `<C-Left>` | 缩小左侧分屏宽度 | Global | `_astrocore_mappings.lua:134` |
| `<C-Right>` | 增大右侧分屏宽度 | Global | `_astrocore_mappings.lua:135` |
| `]t` | 下一个 tab | Global | `_astrocore_mappings.lua:124` |
| `[t` | 上一个 tab | Global | `_astrocore_mappings.lua:125` |
| `<leader>x` | Quickfix / Lists 分组 | Global | `_astrocore_mappings.lua:138` |
| `<leader>xq` | 打开 quickfix list | Global | `_astrocore_mappings.lua:139` |
| `<leader>xl` | 打开 location list | Global | `_astrocore_mappings.lua:140` |

### 2.7 UI / Toggle

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>u` | UI / UX 分组 | Global | `_astrocore_mappings.lua:172` |
| `<leader>uA` | 切换 rooter autochdir | Global | `_astrocore_mappings.lua:174` |
| `<leader>ub` | 切换背景 | Global | `_astrocore_mappings.lua:175` |
| `<leader>ud` | 切换 diagnostics | Global | `_astrocore_mappings.lua:176` |
| `<leader>ug` | 切换 signcolumn | Global | `_astrocore_mappings.lua:177` |
| `<leader>u>` | 切换 foldcolumn | Global | `_astrocore_mappings.lua:178` |
| `<leader>ui` | 修改缩进设置 | Global | `_astrocore_mappings.lua:179` |
| `<leader>ul` | 切换 statusline | Global | `_astrocore_mappings.lua:180` |
| `<leader>un` | 切换行号显示模式 | Global | `_astrocore_mappings.lua:181` |
| `<leader>uN` | 切换通知 | Global | `_astrocore_mappings.lua:182` |
| `<leader>up` | 切换 paste mode | Global | `_astrocore_mappings.lua:184` |
| `<leader>us` | 切换拼写检查 | Global | `_astrocore_mappings.lua:185` |
| `<leader>uS` | 切换 conceal | Global | `_astrocore_mappings.lua:186` |
| `<leader>ut` | 切换 tabline | Global | `_astrocore_mappings.lua:187` |
| `<leader>uu` | 切换 URL 高亮 | Global | `_astrocore_mappings.lua:188` |
| `<leader>uv` | 切换 virtual text | Global | `_astrocore_mappings.lua:189` |
| `<leader>uV` | 切换 virtual lines | Global | `_astrocore_mappings.lua:190` |
| `<leader>uw` | 切换自动换行 | Global | `_astrocore_mappings.lua:192` |
| `<leader>uy` | 切换当前 buffer 语法高亮 | Global | `_astrocore_mappings.lua:193` |

### 2.8 插件管理

| Key | Action | Scope | Source |
|---|---|---|---|
| `<leader>p` | 插件管理分组 | Global | `_astrocore_mappings.lua:62` |
| `<leader>pi` | 安装插件 | Global | `_astrocore_mappings.lua:63` |
| `<leader>ps` | 打开 Lazy 状态页 | Global | `_astrocore_mappings.lua:64` |
| `<leader>pS` | 同步插件 | Global | `_astrocore_mappings.lua:65` |
| `<leader>pu` | 检查插件更新 | Global | `_astrocore_mappings.lua:66` |
| `<leader>pU` | 更新插件 | Global | `_astrocore_mappings.lua:67` |
| `<leader>pa` | 更新 Lazy + Mason | Global | `_astrocore_mappings.lua:68` |

## 3. 当前已发现的冲突 / 覆盖关系

### 3.1 明确冲突

当前没有已确认的自定义键位冲突。

此前 `保存` 与 `Flash` 的冲突已通过以下方式解决：

- 启用 autosave
- 保留 `<leader>w` 作为手动保存映射
- 将 Flash 迁移到：
  - `<leader>fw`：Flash word jump
  - `<leader>fc`：Flash char search

### 3.2 你本地覆盖了 Astro 默认值的地方

| Key | 当前生效 | 被覆盖的默认项 |
|---|---|---|
| `<leader>fw` | Flash word jump（你自定义） | 已从默认保存键迁出，不再覆盖保存 |
| `]b` / `[b` | 你自定义 buffer 导航 | 默认也是 buffer 导航，语义一致 |
| `gD` / `gd` / `gy` / `<leader>uY` | 你自定义 LSP 映射 | 默认也定义了这些键，语义基本一致 |
| `<leader>tt` | 你自定义浮动终端 | 覆盖了 ToggleTerm 默认 `<leader>tt` / btm 终端（若安装 `btm`） |
| `<leader>cA` / `<leader>cr` | 你使用较短的 Cloud Dev attach / rename | 默认 Astro 更偏向 `<leader>la` / `<leader>lr` 这类 LSP 分组写法 |

## 4. 建议你重点记忆的高频键

### 日常编辑

- 保留 `<leader>w` 作为手动保存映射
- 将 Flash 迁移到：
  - `<leader>fw`：Flash word jump
  - `<leader>fc`：Flash char search
- `<leader>e`：文件树
- `<leader>o`：聚焦文件树
- `<leader>tt`：浮动终端

### LSP

- `gd` / `gr` / `gi` / `K`
- `<leader>ca` / `<leader>cr`
- `<leader>lf`
- `[e` / `]e`
- `[w` / `]w`

### Buffer / 窗口

- `]b` / `[b`
- `<leader>bd`
- `<leader>bc`
- `<C-H/J/K/L>`

### 调试

- `<F5>` `<F10>` `<F11>` `<F12>`
- `<leader>db` `<leader>dr` `<leader>dx`

## 5. 说明

这份文档已经从“仅自定义映射”升级为：

1. 你的仓库中显式定义的快捷键
2. 当前安装版本下仍然生效的 AstroNvim / AstroCore 默认快捷键
3. 已确认的冲突与覆盖关系

如果你还要，我下一步可以继续帮你做两件事：

- 再生成一份 **极简版 cheatsheet**（只保留 30 个最常用键）
- 或者继续帮你扫一遍是否还有别的潜在键位冲突

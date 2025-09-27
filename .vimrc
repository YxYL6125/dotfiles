call plug#begin()
"============= File Management =============
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }   " 模糊搜索
Plug 'junegunn/fzf.vim'                               " 模糊搜索

" ============= Edit ===========
Plug 'easymotion/vim-easymotion'

" ============= Appearance ============
Plug 'joshdick/onedark.vim'
Plug 'ap/vim-css-color'              " 显示 css 颜色
Plug 'machakann/vim-highlightedyank' " 使 yank 的文档半透明高亮
Plug 'mhinz/vim-signify'             " 显示当前行的 git 状态
Plug 'Yggdroot/indentLine'           " 显示缩进线
Plug 'itchyny/lightline.vim'         " 显示底部导航栏

call plug#end()

" --- 2. 核心配置：将 ',' 设置为 EasyMotion 的专属 Leader 键 ---
" 这是整个配置的基石。所有跳转都将以 ',' 开始。
" 这会覆盖 Vim 的全局 <Leader> 键，但对于以 EasyMotion 为主的用户来说，这是最快的方案。
let g:EasyMotion_leader_key = '<Space>'


" --- 2. 基础功能增强与美化 ---
" 智能大小写匹配
let g:EasyMotion_smartcase = 1

" 修改跳转提示字符：使用更顺手的 'asdf...' 序列
let g:EasyMotion_keys = 'asdfghjklqwertyuiopzxcvbnm'

" 当按下触发键后，在状态栏给出视觉提示
let g:EasyMotion_prompt = 'EasyMotion for: '


" --- 3. 关键快捷键映射 (覆盖默认行为，使其更强大) ---
" 禁用 EasyMotion 的默认映射，我们来完全接管
let g:EasyMotion_do_mapping = 0

" 定义通用映射函数 (Normal, Visual, Operator-pending)
function! s:EasyMotionMap(key, plug)
  execute 'nmap' a:key '<Plug>(easymotion-' . a:plug . ')'
  execute 'vmap' a:key '<Plug>(easymotion-' . a:plug . ')'
  execute 'omap' a:key '<Plug>(easymotion-' . a:plug . ')'
endfunction

" --- 定义核心双向全屏跳转 (现在全部以 <Space> 开头) ---

" <Space>w -> 全屏、双向搜索单词开头
call s:EasyMotionMap('<Space>w', 'bd-w')

" <Space>b -> 全屏、双向搜索单词结尾
call s:EasyMotionMap('<Space>b', 'bd-e')

" <Space>s -> 全屏、双向搜索任意字符 (最常用)
call s:EasyMotionMap('<Space>s', 's')

" <Space>l -> 全屏、双向搜索行
call s:EasyMotionMap('<Space>l', 'bd-jk')

" <Space>f -> 全屏、双向搜索单个字符 (类似原生f键的超级版)
call s:EasyMotionMap('<Space>f', 'f')

" <Space>t -> 全屏、双向搜索到单个字符之前 (类似原生t键的超级版)
call s:EasyMotionMap('<Space>t', 't')


" --- 4. (可选) 更精细的单向跳转映射 ---
" 使用 '<Space><Space>' 作为前缀，与核心功能区分开

" <Space><Space>w -> 从光标处【向前】搜索单词
call s:EasyMotionMap('<Space><Space>w', 'w')
" <Space><Space>b -> 从光标处【向后】搜索单词
call s:EasyMotionMap('<Space><Space>b', 'b')
" <Space><Space>j -> 从光标处【向下】搜索行
call s:EasyMotionMap('<Space><Space>j', 'j')
" <Space><Space>k -> 从光标处【向上】搜索行
call s:EasyMotionMap('<Space><Space>k', 'k')

" ======================== EasyMotion 配置结束 ===========================

" 你可以在这里添加其他非 EasyMotion 的配置...
" 例如，设置全局的 mapleader，它现在和 EasyMotion 的 leader 是独立的
let mapleader = ','
" 现在你可以定义一些比如 ',f' 触发 fzf 的快捷键，而不会和 EasyMotion 冲突
" nnoremap <leader>f :Files<CR>


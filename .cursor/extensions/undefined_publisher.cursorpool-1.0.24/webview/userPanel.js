(function() {
    const vscode = acquireVsCodeApi();

    // DOM元素
    const loginForm = document.getElementById('loginForm');
    const userStatus = document.getElementById('userStatus');
    const loading = document.getElementById('loading');
    const noticeArea = document.getElementById('noticeArea');
    const noticeContent = document.getElementById('noticeContent');
    
    const activationCodeInput = document.getElementById('activationCode');
    const loginBtn = document.getElementById('loginBtn');
    const loginMessage = document.getElementById('loginMessage');
    
    const userId = document.getElementById('userId');
    const vipStatus = document.getElementById('vipStatus');
    const expireTime = document.getElementById('expireTime');
    const chatLimit = document.getElementById('chatLimit');
    const dayScore = document.getElementById('dayScore');
    const statusMessage = document.getElementById('statusMessage');
    const activationCodeDisplay = document.getElementById('activationCodeDisplay');

    const refreshBtn = document.getElementById('refreshBtn');
    const logoutBtn = document.getElementById('logoutBtn');
    const activeBtn = document.getElementById('activeBtn');
    const copyUserIdBtn = document.getElementById('copyUserIdBtn');
    const copyActivationCodeBtn = document.getElementById('copyActivationCodeBtn');

    // 代理设置相关元素
    const proxyInput = document.getElementById('proxyInput');
    const testProxyBtn = document.getElementById('testProxyBtn');
    const saveProxyBtn = document.getElementById('saveProxyBtn');
    const proxyMessage = document.getElementById('proxyMessage');

    // 网络设置相关元素
    const http2Radio = document.getElementById('http2');
    const http11Radio = document.getElementById('http11');
    const http10Radio = document.getElementById('http10');
    const saveNetworkBtn = document.getElementById('saveNetworkBtn');
    const networkMessage = document.getElementById('networkMessage');

    // 事件监听器
    loginBtn.addEventListener('click', handleLogin);
    refreshBtn.addEventListener('click', handleRefresh);
    logoutBtn.addEventListener('click', handleLogout);
    activeBtn.addEventListener('click', handleActivate);
    copyUserIdBtn.addEventListener('click', handleCopyUserId);
    copyActivationCodeBtn.addEventListener('click', handleCopyActivationCode);
    testProxyBtn.addEventListener('click', handleTestProxy);
    saveProxyBtn.addEventListener('click', handleSaveProxy);
    saveNetworkBtn.addEventListener('click', handleSaveNetwork);
    
    // 回车键登录
    activationCodeInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            handleLogin();
        }
    });

    // 处理登录
    function handleLogin() {
        const code = activationCodeInput.value.trim();
        if (!code) {
            showMessage(loginMessage, '请输入激活码', 'error');
            return;
        }

        vscode.postMessage({
            type: 'login',
            activationCode: code
        });
    }

    // 处理刷新
    function handleRefresh() {
        refreshBtn.disabled = true;
        refreshBtn.innerHTML = '<i class="codicon codicon-loading codicon-modifier-spin"></i> 刷新中';
        vscode.postMessage({
            type: 'refresh'
        });
    }

    // 处理登出
    function handleLogout() {
        vscode.postMessage({
            type: 'logout'
        });
    }

    // 处理激活
    function handleActivate() {
        vscode.postMessage({
            type: 'activate'
        });
    }

    // 处理测试代理
    function handleTestProxy() {
        const proxy = proxyInput.value.trim();
        testProxyBtn.disabled = true;
        testProxyBtn.innerHTML = '<i class="codicon codicon-loading codicon-modifier-spin"></i> 检测中';

        vscode.postMessage({
            type: 'testProxy',
            proxy: proxy
        });
    }

    // 处理保存代理
    function handleSaveProxy() {
        const proxy = proxyInput.value.trim();
        saveProxyBtn.disabled = true;
        saveProxyBtn.innerHTML = '<i class="codicon codicon-loading codicon-modifier-spin"></i> 保存中';

        vscode.postMessage({
            type: 'setProxy',
            proxy: proxy
        });
    }

    // 获取选中的HTTP版本
    function getSelectedHttpVersion() {
        if (http2Radio.checked) {return '2';}
        if (http11Radio.checked) {return '1.1';}
        if (http10Radio.checked) {return '1.0';}
        return '1.1'; // 默认值
    }

    // 处理保存网络设置
    function handleSaveNetwork() {
        const httpVersion = getSelectedHttpVersion();
        saveNetworkBtn.disabled = true;
        saveNetworkBtn.innerHTML = '<i class="codicon codicon-loading codicon-modifier-spin"></i> 保存中';

        vscode.postMessage({
            type: 'setNetwork',
            httpVersion: httpVersion
        });
    }

    // 处理复制用户ID
    function handleCopyUserId() {
        const userIdText = userId.textContent;
        if (!userIdText) {
            return;
        }

        // 使用 Clipboard API 复制文本
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(userIdText).then(() => {
                showMessage(statusMessage, '用户ID已复制到剪贴板', 'success');
            }).catch(() => {
                // 降级到传统方法
                fallbackCopyTextToClipboard(userIdText);
            });
        } else {
            // 降级到传统方法
            fallbackCopyTextToClipboard(userIdText);
        }
    }

    // 处理复制激活码
    function handleCopyActivationCode() {
        const activationCode = activationCodeDisplay.dataset.code;
        if (!activationCode) {
            return;
        }

        // 使用 Clipboard API 复制文本
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(activationCode).then(() => {
                showMessage(statusMessage, '激活码已复制到剪贴板', 'success');
            }).catch(() => {
                // 降级到传统方法
                fallbackCopyTextToClipboard(activationCode);
            });
        } else {
            // 降级到传统方法
            fallbackCopyTextToClipboard(activationCode);
        }
    }

    // 降级复制方法
    function fallbackCopyTextToClipboard(text) {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        try {
            document.execCommand('copy');
            showMessage(statusMessage, '用户ID已复制到剪贴板', 'success');
        } catch (err) {
            showMessage(statusMessage, '复制失败，请手动复制', 'error');
        }

        document.body.removeChild(textArea);
    }

    let timer;
    // 显示消息
    function showMessage(element, message, type = 'info') {
        element.textContent = message;
        element.className = `message ${type}`;
        element.style.display = 'block';
        
        // 自动隐藏
        clearTimeout(timer);
        timer = setTimeout(() => {
            element.style.display = 'none';
        }, 10000);
    }

    // 显示加载状态
    function showLoading(show = true) {
        loading.style.display = show ? 'flex' : 'none';
    }

    // 显示登录表单
    function showLoginForm() {
        loginForm.style.display = 'block';
        userStatus.style.display = 'none';
        showLoading(false);
    }

    // 显示用户状态
    function showUserStatus() {
        loginForm.style.display = 'none';
        userStatus.style.display = 'block';
        showLoading(false);
    }

    // 格式化时间
    function formatTime(timestamp) {
        if (!timestamp) {return '未知';}
        const date = new Date(timestamp);
        return date.toLocaleString('zh-CN');
    }

    // 格式化VIP状态
    function formatVipStatus(vip) {
        if (!vip) {return '普通用户';}
        
        const now = Date.now() / 1000;
        if (vip.expire_at > now) {
            return '会员用户';
        } else {
            return '会员已过期';
        }
    }

    // 更新用户信息显示
    function updateUserInfo(user, chatLimitInfo) {
        if (!user) {
            showLoginForm();
            return;
        }

        userId.textContent = user.id.toString();
        vipStatus.textContent = formatVipStatus(user.vip);

        // 显示模糊化的激活码（如果有）
        if (user.activationCode) {
            const code = user.activationCode;
            const maskedCode = maskActivationCode(code);
            activationCodeDisplay.textContent = maskedCode;
            activationCodeDisplay.dataset.code = code; // 存储完整激活码用于复制
        } else {
            activationCodeDisplay.textContent = '无';
            activationCodeDisplay.dataset.code = '';
        }

        if (user.vip && user.vip.expire_at) {
            expireTime.textContent = formatTime(user.vip.expire_at);
        } else {
            expireTime.textContent = '无';
        }

        // 检查是否为有效会员
        const isVipActive = user.vip && user.vip.expire_at && (user.vip.expire_at > Date.now() / 1000);

        // 更新对话频率信息
        if (chatLimitInfo) {
            chatLimit.textContent = formatChatLimit(chatLimitInfo);
        } else {
            chatLimit.textContent = '未知';
        }

        if (isVipActive) {
            // 会员用户：显示今日对话次数
            dayScore.textContent = user.day_score_used ? user.day_score_used.toString() : '0';

            // 显示激活按钮
            activeBtn.style.display = 'block';
        } else {
            // 隐藏激活按钮
            activeBtn.style.display = 'none';
        }

        showUserStatus();
    }

    // 模糊显示激活码，只显示前两位和后两位
    function maskActivationCode(code) {
        if (!code || code.length < 6) {
            return code;
        }
        const firstTwo = code.substring(0, 9);
        const lastTwo = code.substring(code.length - 8);
        const masked = '*'.repeat(4);
        return `${firstTwo}${masked}${lastTwo}`;
    }

    // 格式化对话频率信息
    function formatChatLimit(limitInfo) {
        if (typeof limitInfo === 'string') {
            // 如果是字符串，尝试解析为JSON
            try {
                const parsed = JSON.parse(limitInfo);
                return formatChatLimitObject(parsed);
            } catch (e) {
                // 如果解析失败，直接返回字符串
                return limitInfo;
            }
        } else if (typeof limitInfo === 'object') {
            return formatChatLimitObject(limitInfo);
        }
        return '未知';
    }

    // 格式化对话频率对象
    function formatChatLimitObject(obj) {
        if (obj && typeof obj === 'object') {
            // 尝试提取常见的频率限制字段
            if (obj.limit !== undefined && obj.used !== undefined) {
                return `${obj.used}/${obj.limit}`;
            } else if (obj.remaining !== undefined && obj.total !== undefined) {
                return `${obj.total - obj.remaining}/${obj.total}`;
            } else if (obj.count !== undefined && obj.max !== undefined) {
                return `${obj.count}/${obj.max}`;
            } else {
                // 如果没有标准字段，返回JSON字符串
                return JSON.stringify(obj);
            }
        }
        return '未知';
    }

    // 监听来自扩展的消息
    window.addEventListener('message', event => {
        const message = event.data;
        
        switch (message.type) {
            case 'notice':
                handleNotice(message);
                break;
            case 'loginStatus':
                handleLoginStatus(message);
                break;
            case 'userStatus':
                handleUserStatus(message);
                break;
            case 'activateStatus':
                handleActivateStatus(message);
                break;
            case 'refreshStatus':
                handleRefreshStatus(message);
                break;
            case 'proxyStatus':
                handleProxyStatus(message);
                break;
            case 'proxySetStatus':
                handleProxySetStatus(message);
                break;
            case 'proxyTestStatus':
                handleProxyTestStatus(message);
                break;
            case 'proxyError':
                handleProxyError(message);
                break;
            case 'networkSettings':
                handleNetworkSettings(message);
                break;
            case 'networkSetStatus':
                handleNetworkSetStatus(message);
                break;
            case 'networkError':
                handleNetworkError(message);
                break;
        }
    });

    // 处理通知消息
    function handleNotice(message) {
        if (message.notice && message.notice.html) {
            noticeContent.innerHTML = message.notice.html;
            noticeArea.style.display = 'block';

            // 如果有URL，添加点击事件和样式
            if (message.notice.url) {
                noticeArea.style.cursor = 'pointer';
                noticeArea.title = '点击打开链接';

                // 移除之前的点击事件监听器（如果有）
                noticeArea.removeEventListener('click', handleNoticeClick);

                // 存储URL到元素的数据属性中
                noticeArea.dataset.url = message.notice.url;

                // 添加点击事件监听器
                noticeArea.addEventListener('click', handleNoticeClick);
            } else {
                noticeArea.style.cursor = 'default';
                noticeArea.title = '';
                noticeArea.removeEventListener('click', handleNoticeClick);
                delete noticeArea.dataset.url;
            }
        } else {
            noticeArea.style.display = 'none';
            noticeArea.removeEventListener('click', handleNoticeClick);
        }
    }

    // 处理通知点击事件
    function handleNoticeClick() {
        const url = noticeArea.dataset.url;
        if (url) {
            // 发送消息给扩展，让扩展打开浏览器
            vscode.postMessage({
                type: 'openUrl',
                url: url
            });
        }
    }

    // 处理登录状态
    function handleLoginStatus(message) {
        switch (message.status) {
            case 'loading':
                showLoading(true);
                showMessage(loginMessage, message.message, 'info');
                loginBtn.disabled = true;
                break;
            case 'success':
                showLoading(false);
                showMessage(loginMessage, message.message, 'success');
                loginBtn.disabled = false;
                activationCodeInput.value = '';
                break;
            case 'error':
                showLoading(false);
                showMessage(loginMessage, message.message, 'error');
                loginBtn.disabled = false;
                break;
        }
    }

    // 处理用户状态
    function handleUserStatus(message) {
        showLoading(false);
        refreshBtn.disabled = false;
        refreshBtn.innerHTML = '刷新状态';

        if (message.error) {
            showMessage(statusMessage, message.error, 'error');
        }

        updateUserInfo(message.user, message.chatLimit);
    }

    // 处理激活状态
    function handleActivateStatus(message) {
        switch (message.status) {
            case 'loading':
                showMessage(statusMessage, message.message, 'info');
                activeBtn.disabled = true;
                break;
            case 'success':
                showMessage(statusMessage, message.message, 'success');
                activeBtn.disabled = false;
                break;
            case 'error':
                showMessage(statusMessage, message.message, 'error');
                activeBtn.disabled = false;
                break;
        }
    }

    // 处理刷新状态
    function handleRefreshStatus(message) {
        switch (message.status) {
            case 'loading':
                refreshBtn.disabled = true;
                refreshBtn.innerHTML = '<i class="codicon codicon-loading codicon-modifier-spin"></i> 刷新中';
                break;
            case 'error':
                refreshBtn.disabled = false;
                refreshBtn.innerHTML = '刷新状态';
                showMessage(statusMessage, message.message || '刷新失败', 'error');
                break;
        }
    }

    // 确保ready消息只发送一次
    let readySent = false;

    function sendReadyMessage() {
        if (!readySent) {
            readySent = true;
            vscode.postMessage({
                type: 'ready'
            });
        }
    }

    // 处理代理状态
    function handleProxyStatus(message) {
        proxyInput.value = message.proxy || '';
    }

    // 处理代理设置状态
    function handleProxySetStatus(message) {
        switch (message.status) {
            case 'loading':
                showMessage(proxyMessage, message.message, 'info');
                saveProxyBtn.disabled = true;
                break;
            case 'success':
                showMessage(proxyMessage, message.message, 'success');
                saveProxyBtn.disabled = false;
                saveProxyBtn.innerHTML = '保存';
                break;
            case 'error':
                showMessage(proxyMessage, message.message, 'error');
                saveProxyBtn.disabled = false;
                saveProxyBtn.innerHTML = '保存';
                break;
        }
    }

    // 处理代理测试状态
    function handleProxyTestStatus(message) {
        switch (message.status) {
            case 'loading':
                showMessage(proxyMessage, message.message, 'info');
                testProxyBtn.disabled = true;
                break;
            case 'success':
                showMessage(proxyMessage, message.message, 'success');
                testProxyBtn.disabled = false;
                testProxyBtn.innerHTML = '检测代理';
                break;
            case 'error':
                showMessage(proxyMessage, message.message, 'error');
                testProxyBtn.disabled = false;
                testProxyBtn.innerHTML = '检测代理';
                break;
        }
    }

    // 处理代理错误
    function handleProxyError(message) {
        showMessage(proxyMessage, message.message, 'error');
    }

    // 处理网络设置
    function handleNetworkSettings(message) {
        const httpVersion = message.httpVersion || '1.1';

        // 设置对应的单选按钮
        http2Radio.checked = (httpVersion === '2');
        http11Radio.checked = (httpVersion === '1.1');
        http10Radio.checked = (httpVersion === '1.0');

        // 如果没有匹配的版本，默认选择1.1
        if (!http2Radio.checked && !http11Radio.checked && !http10Radio.checked) {
            http11Radio.checked = true;
        }
    }

    // 处理网络设置保存状态
    function handleNetworkSetStatus(message) {
        switch (message.status) {
            case 'loading':
                showMessage(networkMessage, message.message, 'info');
                saveNetworkBtn.disabled = true;
                break;
            case 'success':
                showMessage(networkMessage, message.message, 'success');
                saveNetworkBtn.disabled = false;
                saveNetworkBtn.innerHTML = '保存';
                break;
            case 'error':
                showMessage(networkMessage, message.message, 'error');
                saveNetworkBtn.disabled = false;
                saveNetworkBtn.innerHTML = '保存';
                break;
        }
    }

    // 处理网络设置错误
    function handleNetworkError(message) {
        showMessage(networkMessage, message.message, 'error');
    }

    // 页面加载完成后通知扩展并获取设置
    function sendReadyMessage() {
        if (!readySent) {
            readySent = true;
            vscode.postMessage({
                type: 'ready'
            });
            // 获取当前代理设置
            vscode.postMessage({
                type: 'getProxy'
            });
            // 获取当前网络设置
            vscode.postMessage({
                type: 'getNetworkSettings'
            });
        }
    }

    // 页面加载完成后通知扩展
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', sendReadyMessage);
    } else {
        // DOM已经加载完成，立即发送
        sendReadyMessage();
    }
})();

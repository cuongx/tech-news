(() => {
    const notification = document.getElementById('cart-notification');
    const channel = 'BroadcastChannel' in window ? new BroadcastChannel('technews-cart') : null;
    let queue = Promise.resolve();
    let timer;
    let busy = 0;
    function show(message, error = false) {
        if (!notification) return;
        clearTimeout(timer);
        notification.querySelector('.cart-notification-message').textContent = message;
        notification.classList.toggle('is-error', error);
        notification.setAttribute('role', error ? 'alert' : 'status');
        notification.hidden = false;
        if (!error) timer = setTimeout(() => { notification.hidden = true; }, 6000);
    }
    notification?.querySelector('button').addEventListener('click', () => { notification.hidden = true; });
    function badge(count) {
        document.querySelectorAll('[data-cart-count]').forEach(element => {
            element.textContent = count > 99 ? '99+' : String(count);
            element.hidden = count === 0;
        });
        document.querySelectorAll('.home-cart').forEach(link => link.setAttribute('aria-label', `Giỏ hàng, ${count} sản phẩm`));
    }
    async function refreshContent() {
        const content = document.getElementById('cart-content');
        if (!content) return;
        const response = await fetch('/Shop/Cart/Content', {cache: 'no-store', credentials: 'same-origin'});
        if (!response.ok) throw new Error('Chưa tải lại được giỏ hàng. Vui lòng tải lại trang để kiểm tra.');
        content.innerHTML = await response.text();
    }
    async function refresh() {
        if (busy) return;
        try {
            const response = await fetch('/Shop/Cart/Summary', {cache: 'no-store', credentials: 'same-origin'});
            if (!response.ok) return;
            badge((await response.json()).count);
            await refreshContent();
        } catch { /* Retain existing content when offline. */ }
    }
    document.addEventListener('click', event => {
        const step = event.target.closest('[data-cart-step]');
        if (!step || step.disabled) return;
        const form = step.closest('form');
        const input = form.querySelector('[name=quantity]');
        input.value = Math.min(99, Math.max(1, (Number(input.value) || 1) + Number(step.dataset.cartStep)));
        form.requestSubmit();
    });
    document.addEventListener('submit', event => {
        const form = event.target;
        if (!form.matches('.product-add-form, .product-purchase-form, [data-cart-update]')) return;
        event.preventDefault();
        const data = new FormData(form);
        const isUpdate = form.hasAttribute('data-cart-update');
        const action = form.action;
        const scope = isUpdate ? document.getElementById('cart-content') : form;
        const enabled = [...scope.querySelectorAll('button:not(:disabled)')];
        enabled.forEach(button => { button.disabled = true; });
        form.setAttribute('aria-busy', 'true');
        busy++;
        queue = queue.then(async () => {
            try {
                const response = await fetch(action, {method: 'POST', body: data, credentials: 'same-origin', headers: {Accept: 'application/json'}});
                if (!response.headers.get('content-type')?.includes('application/json')) {
                    throw new Error(response.status === 400 ? 'Phiên thao tác đã thay đổi. Tải lại trang rồi thử lại.' : 'Chưa xác nhận được thao tác. Hãy mở giỏ hàng để kiểm tra trước khi thử lại.');
                }
                const result = await response.json();
                if (Number.isInteger(result.count)) badge(result.count);
                show(result.message || 'Không thể cập nhật giỏ hàng.', !response.ok);
                if (isUpdate) await refreshContent();
                if (response.ok) channel?.postMessage('changed');
            } catch (error) {
                show(error instanceof TypeError ? 'Mất kết nối. Hãy kiểm tra giỏ hàng trước khi thử thêm lần nữa.' : error.message, true);
            } finally {
                enabled.forEach(button => { if (button.isConnected) button.disabled = false; });
                form.removeAttribute('aria-busy');
                busy--;
            }
        });
    });
    channel?.addEventListener('message', refresh);
    window.addEventListener('focus', refresh);
    window.addEventListener('pageshow', event => { if (event.persisted) refresh(); });
})();

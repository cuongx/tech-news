document.querySelectorAll('.order-status-form').forEach(form => {
    form.addEventListener('submit', event => {
        const reason = form.querySelector('[name="reason"]');
        if (reason && !reason.value.trim()) {
            event.preventDefault();
            reason.setCustomValidity('Vui lòng nhập lý do hủy đơn.');
            reason.reportValidity();
            return;
        }
        if (!window.confirm(form.dataset.confirm)) event.preventDefault();
    });
    const reason = form.querySelector('[name="reason"]');
    if (reason) reason.addEventListener('input', () => reason.setCustomValidity(''));
});

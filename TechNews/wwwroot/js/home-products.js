(() => {
    const track = document.getElementById('home-product-track');
    if (!track) return;
    const controls = track.closest('.home-products').querySelector('.home-product-controls');
    const previous = controls.querySelector('[data-product-step="-1"]');
    const next = controls.querySelector('[data-product-step="1"]');
    const update = () => {
        const maximum = track.scrollWidth - track.clientWidth;
        controls.hidden = maximum <= 2;
        previous.disabled = track.scrollLeft <= 2;
        next.disabled = track.scrollLeft >= maximum - 2;
    };
    controls.addEventListener('click', event => {
        const button = event.target.closest('button[data-product-step]');
        if (!button || button.disabled) return;
        const card = track.querySelector('.home-product-card');
        const step = card.getBoundingClientRect().width + parseFloat(getComputedStyle(track).gap);
        track.scrollBy({left: Number(button.dataset.productStep) * step,
            behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth'});
    });
    track.addEventListener('scroll', update, {passive: true});
    new ResizeObserver(update).observe(track);
    update();
})();

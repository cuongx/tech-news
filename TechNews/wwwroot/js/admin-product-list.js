document.querySelectorAll('.admin-product-thumbnail img').forEach(image => {
    const showFallback = () => {
        image.hidden = true;
        image.nextElementSibling.hidden = false;
    };
    image.addEventListener('error', showFallback);
    if (image.complete && image.naturalWidth === 0) showFallback();
});

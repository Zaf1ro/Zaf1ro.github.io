{% if theme.widget.Categories %}
    <section id="tags" class="widget-area widget_categories">
        <h3 class="widget-title">Categories</h3>
        {{ list_categories(site.categories) }}
    </section>
{% endif %}
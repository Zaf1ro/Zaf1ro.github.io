{% extends "_layout.swig" %}

{% block title %} {{ __('menu.categories') }} · {{ config.title }} {% endblock %}

{% block content %}
  <div class="categories">
    <div class="categories-title">
      {{ _p('counter.categories', site.categories.length) }}
    </div>
    <div class="categories-tags">
      {{ list_categories({depth: '3'}) }}
    </div>
  </div>
{% endblock %}

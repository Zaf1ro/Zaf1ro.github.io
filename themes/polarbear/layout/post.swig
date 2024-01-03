{% extends "_layout.swig" %}
{% import '_macro/post.swig' as post_template %}

{% block title %}
{{ page.title }} - {{ config.title }}
{% endblock %}

{% block content %}
  <div class="primary">
    {{ post_template.render(page) }}
  </div>
  {% include '_script/mathjax.swig' %}
{% endblock %}
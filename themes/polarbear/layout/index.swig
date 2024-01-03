{% extends "_layout.swig" %}

{% block title %} 
{{ config.title }} - {{ config.description }}
{% endblock %}

{% block content %}
  <div class="primary" id="home">
    {% for post in page.posts %}
      <div class="post on-home">
        <div class="post-header">
          <h1 class="home-post-title">
            <a class="post-link" href="{{ url_for(post.path) }}">{{ post.title }}</a>
          </h1>

          <div class="post-time">
            {{ full_date(post.date, 'MM/DD/YY') }}
          </div>
        </div>
      </div>
    {% endfor %}
    {% include "_partial/pagination.swig" %}
  </div>
  {% include "_partial/widget.swig" %}
{% endblock %}

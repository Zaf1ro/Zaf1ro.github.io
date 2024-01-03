{% macro render() %}
<div id="archive">
  {% if page.tag %}
    <div class="archive-title tag">
      <h1 class="archive-name">{{ page.tag }}</h1>
    </div>
  {% elif page.category %}
    <div class="archive-title category">
      <h2 class="archive-name">{{ page.category }}</h2>
    </div>
  {% endif %}

  {% for post in page.posts %}
    {% if page.archive %}
      {% set year %}
      {% set post.year = date(post.date, 'YYYY') %}

      {% if post.year !== year %}
        {% set year = post.year %}
        <div class="collection-title">
          <h2 class="archive-year">{{ year }}</h2>
        </div>
      {% endif %}
    {% endif %}

    <div class="archive-post">
      <span class="archive-post-time">
        {{ date(post.date, 'YYYY-MM-DD') }}
      </span>
      <span class="archive-post-title">
        <a href="{{ url_for(post.path) }}" class="archive-post-link">
          {{ post.title }}
        </a>
      </span>
    </div>
  {% endfor %}

  {% include '../_partial/pagination.swig' %}
</div>

{% endmacro %}

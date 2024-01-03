<div class="post-excerpt">
  {% set excerpt = "" %}

  {% if post.description %}
    {% set excerpt = post.description %}
  {% elif post.excerpt %}
    {% set excerpt = post.excerpt %}
  {% endif %}

  {% if excerpt %}
    {{ excerpt }}
  {% endif %}
</div>
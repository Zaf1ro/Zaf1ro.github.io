{% if !is_post() %}
   <nav id="sidebar" class="active on-home">
    <div id="sidebar-title">
      <h1 id="sidebar-title-text">
          <a href="{{ url_for('.') }}" class="logo">{{ config.logo }}</a>
      </h1>
    </div>
    <div id="third">
      {# 
        {% include "./_widget/custom.swig" %}
      #}
      {% include "./_widget/categories.swig" %}
      {% include "./_widget/tags.swig" %}
    </div>
  </nav>
{% else %}
  <nav id="sidebar" class="active on-post">
    <div id="third">
      <div id="sidebar-title">
        <h1 id="sidebar-title-text">
            <a href="{{ url_for('.') }}" class="logo">{{ config.logo }}</a>
        </h1>
      </div>
      {% include "./_widget/google.swig" %}
      {% include "./toc.swig" %}
    </div>
  </nav>
{% endif %}
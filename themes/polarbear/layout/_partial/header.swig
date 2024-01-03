<div class="site-header-inner">
  {% if is_post() %}
  <button class="nav-mobile-button on-post" id="sidebarCollapse">
  {% else %}
  <button class="nav-mobile-button on-home" id="sidebarCollapse">
  {% endif %}
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24"><path d="M24 6h-24v-4h24v4zm0 4h-24v4h24v-4zm0 8h-24v4h24v-4z"/></svg>
  </button>
  
  {% if !is_post() %}
  <h1 class="site-title on-home">
    <a href="{{ url_for('.') }}" class="logo">{{ config.logo }}</a>
  </h1>
  {% endif %}


  <nav id="nav-top">
    {% if theme.menu %}
      {% if !is_post() %}
      <ul id="menu-top" class="nav-top-items on-home">
      {% else %}
      <ul id="menu-top" class="nav-top-items on-post">
      {% endif %}
        {% for name, path in theme.menu %}
          <li class="menu-item">
            <a href="{{ url_for(path) }}">
              {% set itemName = 'menu.' + name.toLowerCase() %}
              {% if itemName.startsWith('menu') %}
                {{ name }}
              {% else %}
                {{ __(itemName) }}
              {% endif %}
            </a>
          </li>
        {% endfor %}
      </ul>
    {% endif %}
  </nav>
</div>

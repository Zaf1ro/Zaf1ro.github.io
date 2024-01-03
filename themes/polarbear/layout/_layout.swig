<!DOCTYPE html>
<html lang="{{ config.language }}">
  <head>
    {% include '_partial/head.swig' %}
    <title>{% block title %}{% endblock %}</title>
  </head>

  <body>
    {%- include '_partial/sidebar.swig' %}
    <div id="page">
      <header id="masthead">
        {%- include '_partial/header.swig' %}
      </header>
      <div id="content">
        {% block content %}{% endblock %}
      </div>
    </div>

    {% include '_script/comments.swig' %}
    {% include '_script/libs.swig' %}
    {% include '_script/theme.swig' %}
    {% include '_script/custom.swig' %}
    {% include '_script/config.swig' %}
    {% include '_script/table.swig' %}
    {% include '_script/analytics.swig' %}
    {% include '_script/sidebar.swig' %}
  </body>
</html>

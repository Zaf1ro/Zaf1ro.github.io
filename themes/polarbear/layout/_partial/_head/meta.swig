<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">

{# Website description #}
{% if page.description %}
  <meta name="description" content="{{ page.description }}"/>
{% elif page.title %}
  <meta name="description" content="{{ page.title }}"/>
{% elif config.description %}
  <meta name="description" content="{{ config.description }}"/>
{% endif %}

{# Website keywords #}
{% if page.keywords %}
  <meta name="keywords" content="{{ page.keywords }}" />
{% elif page.tags and page.tags.length %}
  <meta name="keywords" content="{% for tag in page.tags %}{{ tag.name }},{% endfor %}" />
{% endif %}

<meta name="google-site-verification" content="qy4gf0StWj627u-7aIP3WDCLBi3jPYXhm57UC7TUcok" />
<meta name="baidu-site-verification" content="XJoPG7ad2Z" />

<link rel="alternate" hreflang="x-default" href="{{ url }}" />
<link rel="alternate" hreflang="zh" href="{{ url }}" />

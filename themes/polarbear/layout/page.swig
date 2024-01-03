{% extends "_layout.swig" %}

{% block title %} 
{{ page.title }} - {{ config.title }} 
{% endblock %}

{% block content %}
    <div id="article-primary">
        <article class="post">
            <header class="article-header">
                <h1 class="article-title">
                    {{ page.title }}
                </h1>
            </header>
            <div class="post-content">
                {{ page.content }}
            </div>
        </article>
    </div>
{% endblock %}

{% if toc %}
  <div id="toc">
    {{ toc(page.content, {list_number: false, max_depth: 4}) }}
  </div>
{% endif %}
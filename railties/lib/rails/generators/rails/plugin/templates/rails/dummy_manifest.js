
//= link_tree ./images
<% unless options.skip_javascript -%>
//= link application.js
<% end -%>
//= link application.css
<% if mountable? -%>
//= link <%= namespaced_name %>_manifest.js
<% end -%>

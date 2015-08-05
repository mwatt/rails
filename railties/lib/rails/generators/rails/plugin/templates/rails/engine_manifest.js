<% if mountable? -%>
<% unless options.skip_javascript -%>
//= link <%= namespaced_name %>/application.js
<% end -%>
//= link <%= namespaced_name %>/application.css
<% end -%>

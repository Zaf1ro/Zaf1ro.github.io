<script>
$(document).ready(function () {
    $('#sidebarCollapse').on('click', function(){
        $('#sidebar').toggleClass('active');
    });

    $('#toc ol li a').on('click', function(){
        $('#sidebar').toggleClass('active');
    });
});
</script>
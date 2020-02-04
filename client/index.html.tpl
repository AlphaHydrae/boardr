<!DOCTYPE HTML>
<html>
<head>
  <meta charset='UTF-8'>
  <title>Boardr</title>
</head>

<body>
  <div id='elm'></div>
  <script src='/elm.js'></script>
  <script>
    var flags = {
      apiUrl: <%= apiUrl %>,
    };

    var session = localStorage.getItem('boardr');
    if (session) {
      flags.session = JSON.parse(session);
    }

    var app = Elm.Main.init({
      flags: flags,
      node: document.getElementById('elm')
    });

    app.ports.saveSession.subscribe(function(session) {
      if (session) {
        localStorage.setItem('boardr', JSON.stringify(session));
      } else {
        localStorage.removeItem('boardr');
      }
    });
  </script>


</body>
</html>

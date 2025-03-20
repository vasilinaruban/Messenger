// registration

function registration_button() {
    const url = "http://localhost:8080/register";

    const username = document.getElementById("reg_username").value;
    const password = document.getElementById("reg_password").value;

    const data = {
        username: username,
        password: password
    };

    fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    })
    .then(response => response.text())  
    .then(response_text => { console.log("Success: ", response_text); })
    .catch(error => { console.log("Error: ", error); });
}


// authorization

var token = null;
var socket = null;

function authorization_button() {
    const url = "http://localhost:8080/auth";

    const username = document.getElementById("username").value;
    const password = document.getElementById("password").value;

    const data = {
        username: username,
        password: password
    };

    fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(response_data => { 
        console.log("Success: ", response_data); 
        token = response_data.token;
        // console.log(token);

        socket = new WebSocket(`ws://localhost:8080/ws?token=${token}`);

        socket.onopen = function() {
            console.log("Connected to WebSocket server");
        };

        socket.onmessage = function(event) {
            console.log("Received from server:", event.data);
        };    

        socket.onclose = function() {
        console.log("Disconnected from WebSocket server");
        };
    })
    .catch(error => { console.log("Error: ", error); });
}

// sending messages

function send_message_button() {
    var message = document.getElementById("message").value;
    // console.log(message);

    socket.send(message);
}

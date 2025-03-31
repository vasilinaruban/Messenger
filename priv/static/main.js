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


            socket.send(JSON.stringify({
                type: "get_contacts",
                user: username
            }));
        };

        socket.onmessage = function(event) {
            try {
                const messageData = JSON.parse(event.data);
                if (messageData.type === "message") {
                    displayMessage({
                        type: "message",
                        from: messageData.from,
                        text: messageData.text,
                        timestamp: messageData.timestamp
                    });
                }
                else if (messageData.type === "contacts") {
                    console.log("Received contacts:", messageData.contact);
                    displayContacts(messageData.contact); 
                }
            } catch (e) {
                console.error("Error parsing message:", e);
            }
        };   

        socket.onerror = function(error) {
            console.error("WebSocket Error:", error);
        };
        
        socket.onclose = function(event) {
            if (event.wasClean) {
                console.log(`Connection closed cleanly, code=${event.code}, reason=${event.reason}`);
            } else {
                console.error('Connection died');
            }
        };
    })
    .catch(error => { console.log("Error: ", error); });
}

// sending messages

function send_message_button() {
    const message = document.getElementById("message").value;
    const receiver = document.getElementById("receiver").value;

    if (!message || !receiver) {
        alert("Please enter both message and receiver");
        return;
    }

    const data = {
        type: "message",
        to: receiver,
        text: message
    };

    console.log("Sending message: ", data);
    socket.send(JSON.stringify(data));
    
    document.getElementById("message").value = "";
    
    displayMessage({
        type: "message",
        from: "You",
        text: message
    });
}

function displayMessage(messageData) {
    const chatContainer = document.getElementById('chat-messages');
    
    const messageElement = document.createElement('div');
    messageElement.style.margin = '5px 0';
    messageElement.style.padding = '8px';
    messageElement.style.backgroundColor = '#f0f0f0';
    messageElement.style.borderRadius = '4px';
    
    if (messageData.type === "message") {
        messageElement.innerHTML = `
            <strong>${messageData.from}:</strong> 
            ${messageData.text}
            <small style="color: #666; margin-left: 10px;">
                ${new Date().toLocaleTimeString()}
            </small>
        `;
    } else if (messageData.type === "error") {
        messageElement.style.color = 'red';
        messageElement.textContent = `Error: ${messageData.message}`;
    } else {
        messageElement.textContent = JSON.stringify(messageData);
    }
    
    chatContainer.appendChild(messageElement);
    
    chatContainer.scrollTop = chatContainer.scrollHeight;
}

function displayContacts(contacts) {
    const contactsContainer = document.getElementById('contacts-list');
    contactsContainer.innerHTML = ''; 
    
    if (contacts && contacts.length > 0) {
        contacts.forEach(contact => {
            const contactElement = document.createElement('div');
            contactElement.className = 'contact';
            contactElement.textContent = contact;
            contactElement.onclick = function() {
                document.getElementById('receiver').value = contact;
            };
            contactsContainer.appendChild(contactElement);
        });
    } else {
        contactsContainer.textContent = 'No contacts found';
    }
}
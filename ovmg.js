const child_process = require("child_process");
const http = require("http");
const fs = require("fs");

const port = 51342;

// Function for executing the shell command.
function shExec (flag, name, callback) {
    let cmd = `bash ovmg.sh -${flag} ${name}`;
    console.log("executing: " + cmd);
    child_process.exec(cmd, callback);
}

const server = http.createServer(function (req, res) {

    const { headers, method, url } = req;

    console.log(`[REQ] Method: ${method}, URL: ${url}`);

    switch(url) {
        case "/":
            fs.readFile("./view.html", function (err, data) {
                if (err) {
                    res.writeHead(500);
                    res.end();
                } else {
                    res.writeHead(200, {"Content-Type": "text/html"});
                    res.end(data, "utf-8");
                }
            }); 
            break;
        case "/l":
            shExec("l", null, function (error, stdout, stderr) {
                console.log("ERROR: " + error);
                console.log("STDOUT: " + stdout);
                console.log("STDERR: " + stderr);

                res.writeHead(200, {"Content-Type": "text/plain"});
                res.end(stdout, "utf-8");
            });
            break;
        case "/o":
            if (method === "POST" && headers === "Content-type","application/json; charset=UTF-8") {
                let reqBody = "";
                req.addListener("data", (chunk) => { reqBody += chunk; });
                req.addListener("end", function () {
                    reqBody = JSON.parse(reqBody);
                    shExec(reqBody["flag"], reqBody["client"], function (error, stdout, stderr) {
                        console.log("ERROR: " + error);
                        console.log("STDOUT: " + stdout);
                        console.log("STDERR: " + stderr);

                        res.writeHead(200, {"Content-Type": "text/plain"});
                        res.end(stdout, "utf-8");
                    });
                });
            }
            break;
    }
}).listen(port);
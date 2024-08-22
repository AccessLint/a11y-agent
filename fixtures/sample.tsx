import React from "react";

const AccessibilityViolations = () => {
  return (
    <div>
      <html lang="en">
        <head>
          <title>Accessibility Violations</title>
        </head>
        <body>
          <div>
            <p>Here is an emoji not wrapped in a span: 😀</p>

            <img src="image.jpg" alt="image" />

            <a href="https://example.com">Click here</a>

            <a href="#"></a>

            <a href="invalid-url">Invalid Link</a>

            <div aria-activedescendant="some-id"></div>

            <div aria-bogus="true"></div>

            <div aria-hidden="false"></div>

            <div role="invalidRole"></div>

            <input type="text" autoComplete="off" />

            <div onClick={() => alert("Clicked!")}></div>

            <input type="text" />

            <h1></h1>

            <iframe src="some-video.mp4"></iframe>

            <img src="photo.jpg" alt="photo" />

            <div onClick={() => alert("Clicked!")} tabIndex={-1}></div>

            <label>Username</label>
            <input type="text" id="username" />

            <label htmlFor="username">Username</label>
            <input type="text" id="username" />

            <audio controls>
              <source src="audio.mp3" type="audio/mp3" />
            </audio>

            <div onMouseOver={() => {}}></div>

            <div accessKey="s"></div>

            <div aria-hidden="true" tabIndex={0}></div>

            <input type="text" autoFocus />

            <marquee>Scrolling text</marquee>

            <div role="button" onClick={() => {}}></div>

            <div onClick={() => {}}></div>

            <div role="link"></div>

            <div tabIndex={1}></div>

            <select onChange={() => {}}>
              <option>Option 1</option>
              <option>Option 2</option>
            </select>

            <div role="banner"></div>

            <button role="button">Click me</button>

            <table>
              <tr>
                <th>Header</th>
                <th>Another Header</th>
              </tr>
              <tr>
                <td>Data</td>
                <td>More Data</td>
              </tr>
            </table>

            <div tabIndex={5}></div>
          </div>
        </body>
      </html>
    </div>
  );
};

export default AccessibilityViolations;

import Foundation

struct HTMLConstants {
    static let newTabHTML = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>New Tab</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                margin: 0; 
                padding: 2rem; 
                background: #f5f5f5; 
            }
            .container { 
                max-width: 600px; 
                margin: 0 auto; 
                text-align: center; 
            }
            h1 { 
                color: #333; 
                margin-bottom: 2rem; 
            }
            .search { 
                width: 100%; 
                padding: 1rem; 
                font-size: 1.1rem; 
                border: 1px solid #ddd; 
                border-radius: 8px; 
                margin-bottom: 2rem; 
            }
            .links { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); 
                gap: 1rem; 
            }
            .link { 
                background: white; 
                padding: 1rem; 
                border-radius: 8px; 
                text-decoration: none; 
                color: #333; 
                box-shadow: 0 2px 4px rgba(0,0,0,0.1); 
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>New Tab</h1>
            <input type="text" class="search" placeholder="Search or enter URL..." id="search">
            <div class="links">
                <a href="https://www.google.com" class="link">Google</a>
                <a href="https://github.com" class="link">GitHub</a>
                <a href="https://stackoverflow.com" class="link">Stack Overflow</a>
                <a href="https://news.ycombinator.com" class="link">Hacker News</a>
            </div>
        </div>
        <script>
            document.getElementById('search').addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    const query = e.target.value.trim();
                    if (query.includes('.') && !query.includes(' ')) {
                        window.location.href = query.startsWith('http') ? query : 'https://' + query;
                    } else {
                        window.location.href = 'https://www.google.com/search?q=' + encodeURIComponent(query);
                    }
                }
            });
        </script>
    </body>
    </html>
    """
}

using HTTP
using Sockets

const HTTP_ROUTER = HTTP.Router()


function get_header(header)
  message = "\n\t========================================[ HEADER ]========================================\n"

  for content in header
    message *= "\n\t|-> $(content[1]) --> $(content[2])"
  end

  message *= "\n\n\t==========================================================================================\n"

  return message
end


function server()
    print("\n\t\t +------------------------------+")
    print("\n\t\t | Starting server on port [80] |")
    print("\n\t\t +------------------------------+\n\n")

    HTTP.@register(HTTP_ROUTER, "GET", "/", request -> HTTP.Response(read("index.html")))
    HTTP.@register(HTTP_ROUTER, "GET", "/header", request -> HTTP.Response(200, "$(get_header(HTTP.Messages.headers(request)))"))
    HTTP.@register(HTTP_ROUTER, "GET", "/button", request -> HTTP.Response(read("button.html")))
    HTTP.@register(HTTP_ROUTER, "GET", "/passion", request -> HTTP.Response(read("passion.png")))
    HTTP.@register(HTTP_ROUTER, "GET", "/github", request -> HTTP.request("GET", "https://github.com/Enigma717"))

    HTTP.serve(HTTP_ROUTER, Sockets.localhost, 80)
end

server()

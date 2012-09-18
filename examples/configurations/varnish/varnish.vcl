# 
# Default backend definition.  Set this to point to your content
# server.
# 
backend default {
    .host = "127.0.0.1";
    .port = "5000";
}

# If we get told to not cache the request then pass on the cache hit
sub vcl_recv {
  if(
      req.request == "GET" && 
      (req.http.Cache-Control ~ "no-cache" || req.http.Cache-Control ~ "max-age=0")) {
    return (pass);
  }
}

# If we got told by the backing server not to cache then pass otherwise deliver the hit
sub vcl_fetch {
  if(beresp.http.Cache-Control ~ "no-cache" || beresp.ttl <= 0s) {
    set beresp.ttl = 0s;
    return (hit_for_pass);
  }
  return (deliver);
}
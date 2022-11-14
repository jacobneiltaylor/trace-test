package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type StrMap map[string][]string

type EchoResponse struct {
	Host        string `json:"host"`
	Method      string `json:"method"`
	Path        string `json:"path"`
	Headers     StrMap `json:"headers"`
	QueryParams StrMap `json:"query"`
}

func main() {
	router := gin.Default()
	router.POST("/api/v2/spans", fakeZipkin)
	router.GET("/*proxyPath", echoRequest)
	router.Run("localhost:65000")
}

func fakeZipkin(c *gin.Context) {
	c.AbortWithStatus(202)
}

func echoRequest(c *gin.Context) {
	var response_payload = EchoResponse{
		Host:        c.Request.Host,
		Method:      c.Request.Method,
		Path:        c.Request.URL.Path,
		Headers:     StrMap(c.Request.Header),
		QueryParams: StrMap(c.Request.URL.Query()),
	}

	c.IndentedJSON(http.StatusOK, response_payload)
}

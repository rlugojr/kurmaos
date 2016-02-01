package main

import (
	"archive/tar"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"os"
)

type manifest struct {
	Labels []struct {
		Name  string `json:"name"`
		Value string `json:"value"`
	} `json:"labels"`
}

func main() {
	f, err := os.Open(os.Args[1])
	if err != nil {
		panic(err)
	}
	defer f.Close()

	gf, err := gzip.NewReader(f)
	if err != nil {
		panic(err)
	}
	defer gf.Close()

	tr := tar.NewReader(gf)

	for {
		h, err := tr.Next()
		if err != nil {
			panic(err)
		}

		if h.Name != "manifest" && h.Name != "./manifest" {
			continue
		}

		var m *manifest
		if err := json.NewDecoder(tr).Decode(&m); err != nil {
			panic(err)
		}

		var version string
		for _, p := range m.Labels {
			if p.Name == "version" {
				version = p.Value
				break
			}
		}

		fmt.Println(version)
		return
	}
}

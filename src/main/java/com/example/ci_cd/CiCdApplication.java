package com.example.ci_cd;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@RestController
public class CiCdApplication {

	public static void main(String[] args) {
		SpringApplication.run(CiCdApplication.class, args);
	}

	@GetMapping("/hello")
	public String helloWorld() {
        	 return "Hello, World lets connect!";
     }

}

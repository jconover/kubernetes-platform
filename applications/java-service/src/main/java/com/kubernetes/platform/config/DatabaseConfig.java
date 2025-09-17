package com.kubernetes.platform.config;

import com.kubernetes.platform.service.ItemService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@Configuration
@EnableJpaAuditing
public class DatabaseConfig {

    @Bean
    public CommandLineRunner initDatabase(@Autowired ItemService itemService) {
        return args -> {
            itemService.initializeData();
        };
    }
}
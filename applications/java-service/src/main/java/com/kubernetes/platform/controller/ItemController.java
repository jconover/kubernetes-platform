package com.kubernetes.platform.controller;

import com.kubernetes.platform.model.Item;
import com.kubernetes.platform.model.ItemStatus;
import com.kubernetes.platform.service.ItemService;
import io.micrometer.core.annotation.Timed;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
impport jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1")
@CrossOrigin(origins = "*")
public class ItemController {

    private static final Logger logger = LoggerFactory.getLogger(ItemController.class);

    private final ItemService itemService;
    private final Counter requestCounter;
    private final Counter errorCounter;

    @Autowired
    public ItemController(ItemService itemService, MeterRegistry meterRegistry) {
        this.itemService = itemService;
        this.requestCounter = Counter.builder("api_requests_total")
                .description("Total API requests")
                .tag("service", "java-service")
                .register(meterRegistry);
        this.errorCounter = Counter.builder("api_errors_total")
                .description("Total API errors")
                .tag("service", "java-service")
                .register(meterRegistry);
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        requestCounter.increment("endpoint", "/status");
        
        Map<String, Object> status = new HashMap<>();
        status.put("service", "java-service");
        status.put("version", "1.0.0");
        status.put("status", "healthy");
        status.put("timestamp", LocalDateTime.now());
        status.put("environment", System.getenv().getOrDefault("ENVIRONMENT", "development"));
        status.put("node_name", System.getenv().getOrDefault("NODE_NAME", "unknown"));
        status.put("pod_name", System.getenv().getOrDefault("POD_NAME", "unknown"));
        status.put("pod_ip", System.getenv().getOrDefault("POD_IP", "unknown"));
        
        return ResponseEntity.ok(status);
    }

    @GetMapping("/items")
    @Timed(value = "api_request_duration", description = "Time taken to fetch items")
    public ResponseEntity<Map<String, Object>> getAllItems(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String category) {
        
        requestCounter.increment("endpoint", "/items");
        
        try {
            List<Item> items;
            
            if (status != null && category != null) {
                ItemStatus itemStatus = ItemStatus.valueOf(status.toUpperCase());
                items = itemService.getItemsByStatus(itemStatus)
                        .stream()
                        .filter(item -> item.getCategory().equalsIgnoreCase(category))
                        .toList();
            } else if (status != null) {
                ItemStatus itemStatus = ItemStatus.valueOf(status.toUpperCase());
                items = itemService.getItemsByStatus(itemStatus);
            } else if (category != null) {
                items = itemService.getItemsByCategory(category);
            } else {
                items = itemService.getAllItems();
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("items", items);
            response.put("total", items.size());
            response.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            errorCounter.increment("endpoint", "/items");
            logger.error("Error fetching items", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch items", "message", e.getMessage()));
        }
    }

    @GetMapping("/items/{id}")
    @Timed(value = "api_request_duration", description = "Time taken to fetch item by ID")
    public ResponseEntity<?> getItemById(@PathVariable Long id) {
        requestCounter.increment("endpoint", "/items/{id}");
        
        try {
            Optional<Item> item = itemService.getItemById(id);
            if (item.isPresent()) {
                return ResponseEntity.ok(item.get());
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            errorCounter.increment("endpoint", "/items/{id}");
            logger.error("Error fetching item with ID: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch item", "message", e.getMessage()));
        }
    }

    @PostMapping("/items")
    @Timed(value = "api_request_duration", description = "Time taken to create item")
    public ResponseEntity<?> createItem(@Valid @RequestBody Item item) {
        requestCounter.increment("endpoint", "POST /items");
        
        try {
            Item createdItem = itemService.createItem(item);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Item created successfully");
            response.put("item", createdItem);
            response.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            errorCounter.increment("endpoint", "POST /items");
            logger.error("Error creating item", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to create item", "message", e.getMessage()));
        }
    }

    @PutMapping("/items/{id}")
    @Timed(value = "api_request_duration", description = "Time taken to update item")
    public ResponseEntity<?> updateItem(@PathVariable Long id, @Valid @RequestBody Item itemDetails) {
        requestCounter.increment("endpoint", "PUT /items/{id}");
        
        try {
            Item updatedItem = itemService.updateItem(id, itemDetails);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Item updated successfully");
            response.put("item", updatedItem);
            response.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                return ResponseEntity.notFound().build();
            }
            errorCounter.increment("endpoint", "PUT /items/{id}");
            logger.error("Error updating item with ID: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to update item", "message", e.getMessage()));
        }
    }

    @DeleteMapping("/items/{id}")
    @Timed(value = "api_request_duration", description = "Time taken to delete item")
    public ResponseEntity<?> deleteItem(@PathVariable Long id) {
        requestCounter.increment("endpoint", "DELETE /items/{id}");
        
        try {
            itemService.deleteItem(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Item deleted successfully");
            response.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                return ResponseEntity.notFound().build();
            }
            errorCounter.increment("endpoint", "DELETE /items/{id}");
            logger.error("Error deleting item with ID: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to delete item", "message", e.getMessage()));
        }
    }

    @GetMapping("/items/categories")
    public ResponseEntity<Map<String, Object>> getCategories() {
        requestCounter.increment("endpoint", "/items/categories");
        
        try {
            List<String> categories = itemService.getAllCategories();
            
            Map<String, Object> response = new HashMap<>();
            response.put("categories", categories);
            response.put("count", categories.size());
            response.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            errorCounter.increment("endpoint", "/items/categories");
            logger.error("Error fetching categories", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch categories", "message", e.getMessage()));
        }
    }

    @GetMapping("/items/search")
    public ResponseEntity<Map<String, Object>> searchItems(@RequestParam String keyword) {
        requestCounter.increment("endpoint", "/items/search");
        
        try {
            List<Item> items = itemService.searchItems(keyword);
            
            Map<String, Object> response = new HashMap<>();
            response.put("items", items);
            response.put("total", items.size());
            response.put("keyword", keyword);
            response.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            errorCounter.increment("endpoint", "/items/search");
            logger.error("Error searching items with keyword: {}", keyword, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to search items", "message", e.getMessage()));
        }
    }

    @GetMapping("/items/stats")
    public ResponseEntity<Map<String, Object>> getItemStats() {
        requestCounter.increment("endpoint", "/items/stats");
        
        try {
            Map<String, Object> stats = new HashMap<>();
            stats.put("total", itemService.getAllItems().size());
            stats.put("active", itemService.getItemCountByStatus(ItemStatus.ACTIVE));
            stats.put("inactive", itemService.getItemCountByStatus(ItemStatus.INACTIVE));
            stats.put("pending", itemService.getItemCountByStatus(ItemStatus.PENDING));
            stats.put("archived", itemService.getItemCountByStatus(ItemStatus.ARCHIVED));
            stats.put("categories", itemService.getAllCategories().size());
            stats.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            errorCounter.increment("endpoint", "/items/stats");
            logger.error("Error fetching item statistics", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch statistics", "message", e.getMessage()));
        }
    }
}
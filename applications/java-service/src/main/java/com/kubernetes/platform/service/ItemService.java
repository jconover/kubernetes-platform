package com.kubernetes.platform.service;

import com.kubernetes.platform.model.Item;
import com.kubernetes.platform.model.ItemStatus;
import com.kubernetes.platform.repository.ItemRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class ItemService {

    private static final Logger logger = LoggerFactory.getLogger(ItemService.class);

    private final ItemRepository itemRepository;

    @Autowired
    public ItemService(ItemRepository itemRepository) {
        this.itemRepository = itemRepository;
    }

    public List<Item> getAllItems() {
        logger.debug("Fetching all items");
        return itemRepository.findAll();
    }

    public Optional<Item> getItemById(Long id) {
        logger.debug("Fetching item with ID: {}", id);
        return itemRepository.findById(id);
    }

    public Item createItem(Item item) {
        logger.info("Creating new item: {}", item.getName());
        return itemRepository.save(item);
    }

    public Item updateItem(Long id, Item itemDetails) {
        logger.info("Updating item with ID: {}", id);

        return itemRepository.findById(id)
                .map(item -> {
                    item.setName(itemDetails.getName());
                    item.setDescription(itemDetails.getDescription());
                    item.setCategory(itemDetails.getCategory());
                    item.setStatus(itemDetails.getStatus());
                    return itemRepository.save(item);
                })
                .orElseThrow(() -> new RuntimeException("Item not found with id: " + id));
    }

    public void deleteItem(Long id) {
        logger.info("Deleting item with ID: {}", id);

        if (!itemRepository.existsById(id)) {
            throw new RuntimeException("Item not found with id: " + id);
        }

        itemRepository.deleteById(id);
    }

    public List<Item> getItemsByStatus(ItemStatus status) {
        logger.debug("Fetching items with status: {}", status);
        return itemRepository.findByStatus(status);
    }

    public List<Item> getItemsByCategory(String category) {
        logger.debug("Fetching items in category: {}", category);
        return itemRepository.findByCategory(category);
    }

    public Page<Item> searchItemsByName(String name, Pageable pageable) {
        logger.debug("Searching items by name: {}", name);
        return itemRepository.findByNameContainingIgnoreCase(name, pageable);
    }

    public List<String> getAllCategories() {
        logger.debug("Fetching all categories");
        return itemRepository.findDistinctCategories();
    }

    public long getItemCountByStatus(ItemStatus status) {
        return itemRepository.countByStatus(status);
    }

    public List<Item> searchItems(String keyword) {
        logger.debug("Searching items with keyword: {}", keyword);
        return itemRepository.searchByKeyword(keyword);
    }

    public void initializeData() {
        if (itemRepository.count() == 0) {
            logger.info("Initializing sample data");

            List<Item> sampleItems = List.of(
                new Item("Spring Boot Application", "Main Java microservice using Spring Boot framework", "Backend"),
                new Item("RESTful API", "REST endpoints for CRUD operations", "API"),
                new Item("JPA Entity Manager", "Database operations using Spring Data JPA", "Database"),
                new Item("Actuator Endpoints", "Health checks and metrics for monitoring", "Monitoring"),
                new Item("Prometheus Metrics", "Custom metrics exported for Prometheus", "Observability"),
                new Item("Docker Container", "Containerized Java application", "Infrastructure"),
                new Item("Kubernetes Deployment", "Deployed to Kubernetes cluster", "Orchestration"),
                new Item("Load Balancer", "Service load balancing configuration", "Networking"),
                new Item("Auto Scaling", "Horizontal pod autoscaling setup", "Scaling"),
                new Item("Circuit Breaker", "Resilience pattern implementation", "Resilience")
            );

            itemRepository.saveAll(sampleItems);
            logger.info("Sample data initialized with {} items", sampleItems.size());
        }
    }
}
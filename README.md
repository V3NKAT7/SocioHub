# SocioHub 🏦✨

**SocioHub** is a secure, scalable, and privacy-first FinTech platform engineered to give users control over their "Financial Footprint" while enabling them to create and share dynamic financial stories. 

## 🏗️ System Architecture

Our platform adopts a robust, decoupled, microservices-based architecture structured across 6 core layers to prioritize security, horizontal scalability, and strict data privacy.

### 1. Client Layer
- **Flutter Mobile App**: The primary consumer-facing application where users interact with their financial data, socialize, and generate insights.
- **React Admin Web**: An internal dashboard designated for monitoring referral networks, running marketing campaigns, and identifying potential fraud.

### 2. Entry Layer (Security)
- **WAF & API Gateway**: All incoming traffic routes through a Web Application Firewall and our API Gateway, acting as a secure "Traffic Cop" to handle DDoS protection, rate-limiting, and OAuth2/JWT authentication.

### 3. Logic Hub (EKS Cluster)
Core business logic runs inside an AWS EKS (Kubernetes) Cluster, strictly compartmentalized into microservices:
- **AI/ML Service**: Delivers personalized investment insights and models story engagement.
- **Social Metrics Service**: Manages "likes", "shares", and structural generation of "Financial Story" templates.
- **Auth Service**: Manages identity and access control.
- **Referral Service**: Tracks referral links, verifies sign-ups, and fulfills rewards.
- **Financial Proxy Service**: Acts as a stateless intermediary to aggregate banking data securely.

### 4. Event-Driven Messaging Layer
To prevent bottlenecks and decouple services, we utilize **Apache Kafka** as our inter-service backbone, supporting asynchronous workflows (e.g., triggering simultaneous AI sentiment analysis and reward calculation after a story share).

### 5. Multi-Database Data Layer
- **PostgreSQL**: Used for strong ACID-compliant data like financial ledgers, transactional referral rewards, and user accounts.
- **MongoDB**: High-velocity NoSQL storage designed for unstructured social behaviors like timelines, feeds, and raw engagement metrics.

### 6. Privacy-First "Transient Data Zone"
Our system embraces a **Zero-Persistence Policy** regarding sensitive raw bank data (account balances, transaction histories) aggregated natively from Plaid/Yodlee workflows.
- **Cached in Redis** utilizing a strict 15–30 minute Time-To-Live (TTL).
- By allowing sensitive external data to "evaporate" securely without touching Postgres/Mongo, we strictly minimize PCI/DSS compliance scope and fundamentally protect user privacy.

---

*This application is built with zero-compromise security conventions at its core.*

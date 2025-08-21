variable "repository_name" {
  description = "Назва ECR репозиторію"
  type        = string
}

variable "image_tag_mutability" {
  description = "Можливість змінювати теги образів (MUTABLE або IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Чи сканувати образи на вразливості при завантаженні"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Тип шифрування (AES256 або KMS)"
  type        = string
  default     = "AES256"
}

variable "enable_lifecycle_policy" {
  description = "Чи включити політику життєвого циклу"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Максимальна кількість образів для збереження"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Теги для ECR репозиторію"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "goit"
  }
}

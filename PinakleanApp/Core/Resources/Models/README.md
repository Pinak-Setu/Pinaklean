Pinaklean/PinakleanApp/Core/Resources/Models/README.md
# ML Models Directory

This directory should contain pre-trained Core ML models for intelligent file analysis.

## Expected Models

### SafetyModel.mlmodelc
A Core ML model that predicts file safety scores based on:
- File size
- Age (days since modification)
- Path depth
- Location (system/user directories)
- File extensions

**Input Features:**
- `file_size` (Double): Size in bytes
- `days_since_modified` (Double): Days since last modification
- `path_depth` (Double): Directory depth
- `is_recent` (Int64): 1 if modified within 7 days
- `is_old` (Int64): 1 if modified more than 365 days ago
- `is_system_dir` (Int64): 1 if in system directories
- `is_user_dir` (Int64): 1 if in user directories
- `has_common_extensions` (Int64): 1 if has common file extension

**Output:**
- `safety_score` (Int64): Safety score from 0-100

### ContentTypeModel.mlmodelc
A Core ML model that predicts content type based on file name and extension.

**Input Features:**
- `file_extension` (String): File extension (lowercased)
- `file_name` (String): Full filename

**Output:**
- `content_type` (String): One of ["image", "video", "audio", "document", "archive", "application", "data"]

## Model Training

To train these models:

1. **Safety Model:** Use labeled data of files users kept vs deleted
2. **Content Type Model:** Use file extension and header analysis

Models should be compiled to `.mlmodelc` format for deployment.

## Fallback Behavior

If models are not present, the system falls back to heuristic-based analysis which provides good baseline functionality while models are being developed.
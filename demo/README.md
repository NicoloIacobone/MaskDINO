## Getting Started with MaskDINO

This document provides a brief intro of the usage of **MaskDINO**.

Please see [Getting Started with Detectron2](https://github.com/facebookresearch/detectron2/blob/master/GETTING_STARTED.md) for full usage.


### Inference Demo with Pre-trained Models

1. Pick a model and its config file
- for example
   - config file at `/configs/coco/instance-segmentation/maskdino_R50_bs16_50ep_3s.yaml`.
   - Model file [MaskDINO (hid 1024) ](https://github.com/IDEA-Research/detrex-storage/releases/download/maskdino-v0.1.0/maskdino_r50_50ep_300q_hid1024_3sd1_instance_maskenhanced_mask46.1ap_box51.5ap.pth)
2. We provide `demo.py` that is able to demo builtin configs. 
3. Run it with:
```
cd demo/
python demo.py --config-file /configs/coco/instance-segmentation/maskdino_R50_bs16_50ep_3s.yaml \
  --input input1.jpg input2.jpg \
  [--other-options]
  --opts MODEL.WEIGHTS /path/to/model_file
```
The configs are made for training, therefore we need to specify `MODEL.WEIGHTS` to a model from model zoo for evaluation.
This command will run the inference and show visualizations in an OpenCV window.

For details of the command line arguments, see `demo.py -h` or look at its source code
to understand its behavior. Some common arguments are:
* To run __on your webcam__, replace `--input files` with `--webcam`.
* To run __on a video__, replace `--input files` with `--video-input video.mp4`.
* To run __on cpu__, add `MODEL.DEVICE cpu` after `--opts`.
* To save outputs to a directory (for images) or a file (for webcam or video), use `--output`.

> **Warning:** if `--output` is a directory, the result is saved as
> `<output_dir>/<input_filename>`. If your input image already lives in that directory,
> this silently overwrites it. Use a different output directory/filename to be safe.

### Switching between task variants

MaskDINO is trained for four task variants. `demo.py` doesn't need any code changes to
switch between them — it picks the right visualization (instance/panoptic/semantic)
automatically from what the model outputs. Just pass the matching `--config-file` and
`MODEL.WEIGHTS` for the variant you want:

| Variant | Config | Weights |
|---|---|---|
| Instance segmentation (COCO) | `configs/coco/instance-segmentation/maskdino_R50_bs16_50ep_3s.yaml` | [download](https://github.com/IDEA-Research/detrex-storage/releases/download/maskdino-v0.1.0/maskdino_r50_50ep_300q_hid1024_3sd1_instance_maskenhanced_mask46.1ap_box51.5ap.pth) |
| Panoptic segmentation (COCO) | `configs/coco/panoptic-segmentation/maskdino_R50_bs16_50ep_3s_dowsample1_2048.yaml` | [download](https://github.com/IDEA-Research/detrex-storage/releases/download/maskdino-v0.1.0/maskdino_r50_50ep_300q_hid2048_3sd1_panoptic_pq53.0.pth) |
| Semantic segmentation (ADE20K) | `configs/ade20k/semantic-segmentation/maskdino_R50_bs16_160k_steplr.yaml` | [download](https://github.com/IDEA-Research/detrex-storage/releases/download/maskdino-v0.1.0/maskdino_r50_50ep_100q_celoss_hid1024_3s_semantic_ade20k_48.7miou.pth) |
| Semantic segmentation (Cityscapes) | `configs/cityscapes/semantic-segmentation/maskdino_R50_bs16_90k_steplr.yaml` | [download](https://github.com/IDEA-Research/detrex-storage/releases/download/maskdino-v0.1.0/maskdino_r50_50ep_100q_celoss_hid1024_3s_semantic_cityscapes_79.8miou.pth) |

(all four are R50 backbones; see the main [README](../README.md#results) for larger
Swin-L variants and their checkpoints — same config/weights swap applies)

Example, panoptic segmentation:
```
cd demo/
python demo.py --config-file ../configs/coco/panoptic-segmentation/maskdino_R50_bs16_50ep_3s_dowsample1_2048.yaml \
  --input input1.jpg \
  --output /path/to/output_dir/ \
  --opts MODEL.WEIGHTS /path/to/maskdino_r50_50ep_300q_hid2048_3sd1_panoptic_pq53.0.pth
```

Example, semantic segmentation (Cityscapes):
```
cd demo/
python demo.py --config-file ../configs/cityscapes/semantic-segmentation/maskdino_R50_bs16_90k_steplr.yaml \
  --input input1.jpg \
  --output /path/to/output_dir/ \
  --opts MODEL.WEIGHTS /path/to/maskdino_r50_50ep_100q_celoss_hid1024_3s_semantic_cityscapes_79.8miou.pth
```



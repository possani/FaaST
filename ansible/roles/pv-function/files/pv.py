from PIL import Image, ImageFilter


def main(args):
    images = args['images']

    for image_name in images:
        try:
            image = Image.open('/files/' + image_name)
            image.transpose(Image.FLIP_TOP_BOTTOM)
            image.transpose(Image.ROTATE_180)
            image.thumbnail((128, 128))
            image.save('/files/thumbnail_' + image_name)
        except Exception as e:
            return {"Message": "Image: {} failed with error {}".format(image_name, str(e))}

    return {"Message": "{} images were processed".format(len(images))}

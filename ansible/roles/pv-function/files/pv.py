from PIL import Image, ImageFilter


def main(args):
    image_name = args['image']
    try:
        image = Image.open('/files/' + image_name)
        image.thumbnail((128, 128))
        image.save('/files/thumbnail_' + image_name)

        return {"Message": "File {} written to disk.".format('thumbnail_' + image_name)}
    except Exception as e:
        return {"error": str(e)}

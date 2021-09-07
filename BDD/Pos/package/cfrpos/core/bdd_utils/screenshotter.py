import os
from pywinauto import application
from datetime import datetime
import psutil

def get_process_id(process_name: str):
    proc_iter = psutil.process_iter(attrs=['pid', 'name'])
    pos_engine = [p.info for p in proc_iter if p.info['name'] == process_name]

    return pos_engine[0]['pid']

def connect_to_app(pid):    
    app = application.Application()
    app.connect(process=pid)

    return app

def capture_image(app):
    hwin = app.top_window()
    hwin.set_focus()
    img = hwin.capture_as_image()

    return img

def save_screenshot(directory: str, img):
    filename: str = datetime.now().strftime("%d-%m-%Y-%H-%M-%S.%f.png")
    path: str = os.path.join(directory, filename)
    img.save(path)
    print("A screenshot {} saved".format(filename))

def take_screenshot(directory: str, process_name: str = 'PosEngine.exe'):
    pid: int = get_process_id(process_name)
    app = connect_to_app(pid)
    img = capture_image(app)
    save_screenshot(directory, img)
use tracing_subscriber;
use waylanddisplaycore::WaylandDisplay;

fn run_display(render_node: Option<String>) {
    let mut dpy = match WaylandDisplay::new(render_node) {
        Ok(dpy) => {
            println!("Wayland display created successfully!");
            // 在这里可以使用 dpy，不需要转换为原始指针
            Ok(dpy)
        }
        Err(err) => {
            tracing::error!(?err, "Failed to create wayland display.");
            eprintln!("Error: {:?}", err);
            Err(err)
        }
    };

    // 在这里可以使用 dpy
    // 当 dpy 离开作用域时会自动释放
    let mut dpy = dpy.expect("Failed to create wayland display.");
    dpy.add_input_device("/dev/input/event20");
    dpy.add_input_device("/dev/input/event21");
    println!("Added input devices");
    std::thread::sleep(std::time::Duration::from_secs(1000));
}

fn main() {
    // 初始化 tracing（对应原代码第22行）
    tracing_subscriber::fmt::try_init().ok();

    // 设置 render_node（可以是 None 或 Some(String)）
    // let render_node = None; // 或者 Some("/dev/dri/renderD128".to_string())
    let render_node = Some("/dev/dri/renderD128".to_string());

    // 执行原代码的核心逻辑（对应原代码第24-30行）
    let handle = std::thread::spawn(move || {
        run_display(render_node);
    });
    loop {
        println!("Sleeping for 1000 seconds");
        std::thread::sleep(std::time::Duration::from_secs(1000));
    }
    handle.join().unwrap();
}

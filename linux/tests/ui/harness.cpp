#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QQuickWindow>
#include <QQuickStyle>
#include <QTimer>
#include <QUrl>
#include <QVariantMap>
// usage: harness <dir> <w> <h> <scenario> <page main|settings> <out.png> [nomin]
int main(int argc, char **argv)
{
    if (argc < 7) return 64;
    QString dir = argv[1];
    int w = QString(argv[2]).toInt(), h = QString(argv[3]).toInt();
    QString scenario = argv[4], page = argv[5], out = argv[6];
    bool nomin = argc > 7;
    QQuickStyle::setStyle("Material");
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    QQmlComponent comp(&engine, QUrl::fromLocalFile(dir + "/Mock.qml"));
    QObject *mock = comp.createWithInitialProperties({{"scenario", scenario}});
    if (!mock) { qWarning() << comp.errors(); return 65; }
    engine.rootContext()->setContextProperty("airPodsTrayApp", mock);
    engine.rootContext()->setContextProperty("PHONE_MAC_ADDRESS", "");
    engine.load(QUrl::fromLocalFile(dir + "/Main.qml"));
    if (engine.rootObjects().isEmpty()) return 66;
    auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (nomin) { win->setMinimumSize(QSize(0, 0)); win->setProperty("minimumWidth", 0); win->setProperty("minimumHeight", 0); }
    win->resize(w, h);
    win->show();
    QTimer::singleShot(700, &app, [=]() {
        if (page == "settings") QMetaObject::invokeMethod(win, "reopen", Q_ARG(QVariant, "settings"));
        QTimer::singleShot(900, win, [=]() {
            QImage img = win->grabWindow();
            img.save(out);
            // report actual size so clamping by min size is visible
            fprintf(stderr, "actual %dx%d\n", win->width(), win->height());
            QCoreApplication::quit();
        });
    });
    return app.exec();
}

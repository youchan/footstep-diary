RubyKaigi 2017でRubyのVirtual DOM実装であるHyaliteについて発表しました。
このエントリではHyaliteについて書こうと思います。
このエントリは仮想DOM/Flux Advent Calendar の 20日目の記事として書いています。

Rubyはサーバーサイドの言語という印象があると思いますが、OpalというRubyからJavaScriptへのトランパイラを使うことによって、
Rubyでフロントエンドのコードを書くことができます。
Virtual DOMの実装に関してはReact.jsを参考に実装しました。React.jsの実装を参考にしてRubyで独自に実装していこうと思っていたのですが、React.jsのコードが難しくて私にはとても読み解くことはできませんでした。そこで方針を少し変更してReact.jsのコアのロジックはJavaScriptのコードをそのままRubyに移植して、少しずつRubyらしいコードにリファクタリングしていくことにしました。
Hyaliteの今の状態はやっとサンプルのプログラムが動くという感じです。具体的には、[TodoMVC](https://github.com/youchan/hyalite-todo)とRubyKaigiでの発表に使ったスライドアプリケーション(https://github.com/youchan/hyaslide )です。
どちらもソースコードを公開していますが、スライドのほうは発表のための間に合わせのコードなのでいろいろ酷い部分があるかと思います。
ここでは、TodoMVCのコードをみながらにHyaliteについて解説しようと思います。

## TodoMVC
ソースコードはhttps://github.com/youchan/hyalite-todo にあります。
すべてのコードを説明するのは大変ですので、ここでは

* config.ru
* index.html.haml
* app/application.rb

の3つのファイルについて説明します。

## config.ru

config.ruはRubyのWebアプリケーションサーバーのエントリポイントになる設定ファイルです。
ここでは、`Opal::Server`の設定をしています。`Opal::Server`はサーバーサイドでRubyのコードをJavaScriptにコンパイルしてクライアントサイドに返します。

```ruby
require 'bundler'
Bundler.require

run Opal::Server.new { |s|
  s.append_path 'app'
  s.append_path 'node_modules'

  s.debug = true
  s.main = 'application'
  s.index_path = 'index.html.haml'
}
```

## index.html.haml
Opalにはopal-hamlというOpalでhamlを使うためのライブラリがあります。

```haml
!!!
%html(lang="en" data-framework="hyalite")
  %head
    %meta(charset="utf-8")
    %title Hyalite • TodoMVC
    %link(rel="stylesheet" href="node_modules/todomvc-common/base.css")
    %link(rel="stylesheet" href="node_modules/todomvc-app-css/index.css")

  %body
    %section.todoapp
    %footer.info
      %p Double-click to edit a todo
      %p
        Created by
        %a(href="http://github.com/youchan/") youchan
      %p
        Part of
        %a(href="http://todomvc.com") TodoMVC

    = javascript_include_tag 'application'
```

`%section.todoapp`の下にアプリケーションが生成するDOMがマウントされます。
`application.js`というJavaScriptファイルをインクルードするように記述されています。実際には`application.rb`というRubyのコードがOpalによってJavaScriptにコンパイルされます。

## application.rb
クライアントサイドのエントリポイントになります。

### Appクラス
```ruby
module App
  def self.render
    Hyalite.render(Hyalite.create_element(TodoApp, {model: model}), $document['.todoapp'])
  end

  def self.model
    @model ||= TodoModel.new
  end
end
```

`Hyalite.render()`はReactでは`ReactDOM.render()`にあたり、`Hyalite.create_element()`は`React.createElement()`にあたるメソッドです。大体Reactと同じようなコードになることがみてとれます。
`$document['.todoapp']`としているところはDOMのエレメントを取得しています。Hyaliteでは`opal-browser`というライブラリを利用してDOMの操作を行っています。

```ruby
$document.ready do
  App.model.subscribe do
    App.render
  end

  App.render
end
```

ドキュメントが準備できたら、`App.render`を呼びだしてVirtual DOMをレンダリングしています。(結果的に実際のDOMがレンダリングされます。)

### `Hyalite::Component`モジュール

Reactの`createClass()`で作られるコンポーネントに対応するものは、`Hyalite::Component`モジュールを`include`したクラスになります。

```ruby
class TodoApp
  include Hyalite::Component

  def initial_state
    {
      nowShowing: :all,
      editing: nil,
      newTodo: ''
    }
  end
end
```

ここにある、`initial_state`はReactでは`getInitialState()`に対応します。

### `component_did_mount`メソッド

`component_did_mount`メソッドはコンポーネントがマウントされた後に呼ばれます。(そのままですね)
このようなフックはこの他に`component_will_mount`, `component_did_mount`, `component_will_unmount`, `component_will_update`, `component_did_update`などがあります。

```ruby
  def component_did_mount
    router = Router.new
    router.route('/') { set_state({nowShowing: :all}) }
    router.route('/active') { set_state({nowShowing: :active}) }
    router.route('/completed') { set_state({nowShowing: :completed}) }
  end
```

`TodoApp`では`component_did_mount`のなかで、ルーターの設定をしています。ルーターには、`opal-router`というライブラリを使っています。

### `TodoApp#render`
renderのなかの処理をちょっと覗いてみましょう。

```ruby
  def render
    # ---- snip ----
    div(nil,
      header({className: 'header'},
        h1(nil, "todos"),
        input({
          className:'new-todo',
          placeholder:'What needs to be done?',
          autofocus:true,
          onKeyDown: -> (event) { handle_new_todo_key_down(event) },
          onChange: -> (event) { handle_change(event) },
          value: @state[:newTodo]
        })),
      main,
      footer)
  end
```

`create_element`の代りに`header`や`h1`などのメソッドの呼びだしがあります。
HyaliteではReactのJSXの代りにショートハンドを用意しました。
`Hyalite::Component::ShortHand`モジュールを`include`することでショートハンドを利用することできます。

イベントについて見ていくと、以下のコードがあります。

```ruby
          onKeyDown: -> (event) { handle_new_todo_key_down(event) },
```

キーボードイベントを拾って、`handle_new_todo_key_down`というメソッドを呼びだしています。ここでは、Rubyのラムダをつかってコードブロックを参照しています。

## 最後に
駆け足でHyaliteについて見ていきました。まだ生まれたばかりのフレームワークなので、いろいろ不備があると思います。不具合などありましたぜひissueでお知らせください。

Happy hakking!

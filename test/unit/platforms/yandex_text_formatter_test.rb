require File.expand_path('../../../test_helper', __FILE__)

class Redmine2chat::Platforms::Yandex::TextFormatterTest < ActiveSupport::TestCase
  let(:formatter) { Redmine2chat::Platforms::Yandex::TextFormatter }

  it 'converts bold and italic to the Yandex markup' do
    assert_equal '**Иван** __сделал__', formatter.('<b>Иван</b> <i>сделал</i>')
    assert_equal '**Иван** __сделал__', formatter.('<strong>Иван</strong> <em>сделал</em>')
  end

  it 'converts pre blocks into fenced code' do
    assert_equal "**Автор**\n\n```\nтекст\n```", formatter.("<b>Автор</b>\n<pre>текст</pre>")
  end

  it 'converts links' do
    assert_equal '[Задача 1](https://example.org/issues/1)',
                 formatter.('<a href="https://example.org/issues/1">Задача 1</a>')
  end

  it 'unescapes entities and drops unknown tags' do
    assert_equal 'a < b', formatter.('<span>a &lt; b</span>')
  end

  it 'turns br into a line break' do
    assert_equal "a\nb", formatter.('a<br>b')
  end

  it 'returns an empty string for blank input' do
    assert_equal '', formatter.(nil)
    assert_equal '', formatter.('')
  end
end
